function [X info] = kaczmarz(A,b,K,x0,options)
%KACZMARZ Kaczmarz's method (often referred to as ART)
%
%   [X info] = kaczmarz(A,b,K)
%   [X info] = kaczmarz(A,b,K,x0)
%   [X info] = kaczmarz(A,b,K,x0,options)
%
% Implements Kaczmarz's method for the system Ax = b:
%       
%       x^{k+1} = x^k + lambda*(b_i - a^i*x^k)/(||a^i||_2^2)*a^i
%
% where i = (k mod m) + 1.
%
% Input:
%   A          m times n matrix.
%   b          m times 1 vector.
%   K          Number of iterations. If K is a scalar, then K is the maximum
%              number of iterations and only the last iterate is saved.
%              If K is a vector, then the largest value in K is the maximum
%              number of iterations and only iterates corresponding to the
%              values in K are saved, together with the last iterate.
%              If K is empty then a stopping criterion must be specified.
%   x0         n times 1 starting vector. Default: x0 = 0.
%   options    Struct with the following fields:
%       lambda      The relaxation parameter. For this method lambda must
%                   be a scalar.
%       stoprule    Struct containing the following information about the
%                   stopping rule:
%                       type = 'none' : (Default) the only stopping rule
%                                       is the maximum number of iterations.
%                              'DP' : The Discrepancy Principle
%                              'NCP': Normalized Cumulative Perodogram.
%                       taudelta = The product of tau and delta, only
%                                  necessary for DP.
%       nonneg      Logical; if true then nonnegativity in enforced in
%                   each step.
%
% Output:
%   X           Matrix containing the saved iterations.
%   info        Information vector with 2 elements.
%               nfo(1) = 0 : stopped by maximum number of iterations
%                         1 : stopped by NCP-rule
%                         2 : stopped by DP-rule
%               info(2) = no. of iterations.
%
% See also: randkaczmarz, symkaczmarz

% Maria Saxild-Hansen and Per Chr. Hansen, June 11, 2011, DTU Informatics.

% Reference: G. T. Herman, Fundamentals of Computerized Tomography,
% Image Reconstruction from Projections, Springer, New York, 2009. 

[m n] = size(A);
A = A';  % Faster to perform sparse column operations.

% Check the number of inputs.
if nargin < 3
    error('Too few input arguments')
end

% Default value of starting vector x0.
if nargin < 4
    x0 = zeros(n,1);
end

% Check if x0 is empty.
if isempty(x0)
    x0 = zeros(n,1);
end

% The sizes of A, b and x must match.
if size(b,1) ~= m || size(b,2) ~= 1
    error('The size of A and b do not match')
elseif size(x0,1) ~= n || size(x0,2) ~= 1
    error('The size of x0 does not match the problem')
end

% Initialization.
if nargin < 5
    if isempty(K)
        error('No stopping rule specified')
    else
        Knew = sort(K);
        kmax = Knew(end);
        X = zeros(n,length(K));
    end
    
    % Default value of lambda.
    lambda = 0.25;
    % Default stopping rule.
    stoprule = 'NO';    
    
    % Default there is no nonnegativity projection.
    nonneg = false;
end

% Check the contents of options, if present.
if nargin == 5
    
    % Nonnegativity.
    if isfield(options,'nonneg')
        nonneg = options.nonneg;
    else
        nonneg = false;
    end
    
    if isfield(options,'lambda')
        if isnumeric(options.lambda)
            lambda = options.lambda;
            
            if lambda <= 0 || lambda >= 2
                warning('MATLAB:UnstableRelaxParam',...
                    'The lambda value is outside the interval (0,2)');
            end
        else
            error('lambda must be numeric')
        end
    else
        lambda = 0.25;
    end
    
    % Stopping rules
    if isfield(options,'stoprule') && isfield(options.stoprule,'type')
        stoprule = options.stoprule.type;
        if ischar(stoprule)
            if strncmpi(stoprule,'DP',2)
                % DP stopping rule.
                if isfield(options.stoprule,'taudelta')
                    taudelta = options.stoprule.taudelta;
                else
                    error('The factor taudelta must be specified when using DP')
                end
                
                % Check that the first iteration should be performed:
                rk = (b-A'*x0);  % Remember that A is transposed.
                nrk = norm(rk);
                
                if nrk <= taudelta
                    info = [2 0];
                    X = x0;
                    return
                end % end the DP-rule.
                
            elseif strncmpi(stoprule,'NC',2)
                % NCP stopping rule.
                dk = inf;
                q = floor(m/2);
                c_white = (1:q)'./q;
                
                if ~isempty(K)
                    K = [K max(K)+1];
                end
                
            elseif strncmpi(stoprule,'NO',2)
                % No stopping rule.
                if isempty(K)
                    error('No stopping rule specified')
                end
                
            else
                % Other stopping rules.
                error('The chosen stopping rule is not valid')
            end % end different stopping rules.
            
        else
            error('The stoprule type must be a string')
        end % end stoprule is a string.
        
        % Determine the maximum number of iterations and initialize the 
        % output matrix X.
        if isempty(K)
            kmax = inf;
            X = zeros(n,1);
        else
            Knew = sort(K);
            kmax = Knew(end);
            X = zeros(n,length(K));
        end % end if isempty K.            
    else
        % Determine the maximum number of iterations and initialize the
        % output vector X.
        if isempty(K)
            error('No stopping rule specified')
        else
            Knew = sort(K);
            kmax = Knew(end);
            X = zeros(n,length(K));
            stoprule = 'NO';
        end
        
    end % end stoprule type specified.
end % end if nargin includes options.

% Initialize the values.
xk = x0;
xki = xk;
normAi = full(abs(sum(A.*A,1)));  % Remember that A is transposed.
I = find(normAi>0);

stop = 0;
k = 0;
l = 0;
klast = 0;

while ~stop
    k = k + 1;
    % The kaczmarz sweep.
    for i = I
        ai = full(A(:,i))';  % Remember that A is transposed.
        bi = b(i);
        r = bi - ai*xki;
        xki = xki + (lambda*r/normAi(i))*ai';
        if nonneg, xki(xki<0) = 0; end
    end
    xk1 = xki;
    
    % Stopping rules.
    if strncmpi(stoprule,'DP',2)
        % DP stopping rule.
        rk1 = (b - A'*xk1);  % Remember that A is transposed.
        nrk = norm(rk1);
        
        if nrk <= taudelta || k >= kmax
            stop = 1;
            if k >= kmax
                info = [0 k];
            else
                info = [2 k];
            end
        end % end the DP-rule.
        
    elseif strncmpi(stoprule,'NC',2)
        % NCP stopping rule.
        rk1 = b-A'*xk1;  % Remember that A is transposed.
        rkh = fft(rk1);
        pk = abs(rkh(1:q+1)).^2;
        c = zeros(q,1);
        for index = 1:q
            c(index) = sum(pk(2:index+1))/sum(pk(2:end));
        end
        
        if dk < norm(c-c_white) || k >= kmax
            stop = 1;
            xk1 = xk;
            
            if k >= kmax
                info = [0 k-1];
            else
                info = [1 k-1];
            end
            
        else
            dk = norm(c-c_white);
        end % end NCP-rule.
        
    elseif strncmpi(stoprule,'NO',2)
        % No stopping rule.
        if k >= kmax
            stop = 1;
            info = [0 k];
        end
    end % end stoprule type.
        
    % If the current iteration is requested saved.
    if (~isempty(K) && k == Knew(l+1)) || stop
        l = l + 1;
        % Saves the current iteration.
        if strncmpi(stoprule,'NC',2)
            if ~(stop && klast == k-1)
                X(:,l) = xk1;
            else
                l = l - 1;
            end
        else
            X(:,l) = xk1;
        end
        klast = k;

    end
    % Updates xk.
    xk = xk1;
end
% Save only the saved iterations.
X = X(:,1:l);