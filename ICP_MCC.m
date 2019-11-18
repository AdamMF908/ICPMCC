function [R, t, corr, Error_of_iter, TData, TotalStep] = ICP_MCC(DData, MData, R, t)

% This is an implementation of the Iterative Closest Point algorithm based on maximum correntropy criterion.
% The function takes two data sets(2D or 3D) and registers DData with MData.
% The code iterates till no more correspondences can be found.
% DData->MData
% Arguments: MData - M x D matrix of the x, y and z coordinates of data set 1, D is the dimension of point set
%            DData - N x D matrix of the x, y and z coordinates of data set 2
%            tri   - optional argument. obtained by tri = delaunayn(DData');
%
% Returns: R - D x D accumulative rotation matrix used to register DData
%          t - D x 1 accumulative translation vector used to register DData
%          corr - M x D matrix of the index no.s of the corresponding points of
%                 MData and DData and their corresponding Euclidean distance
%          error - the  error between the corresponding points
%                  of MData and DData (normalized with res)
%          TData - M x D matrix of the registered DData
%
% Copyright: This code is written by Shaoyi Du {dushaoyi@gmail.com}
%            Institute of Artificial Intelligence and Robotics, Xi'an Jiaotong University, P.R.China
%            The code may be used, modified and distributed for research purposes with acknowledgement of the author and inclusion of this copyright information.
%
%			 Modified by  Guanglin Xu on 2016/3/3.
%			 No other files are needed.

% ��������
Epsilon = 10^-7;
MaxStep = 100            ;   % the max step of iteration
IS_Step_Show = 0             ;   %�Ƿ���ʾÿһ������׼Ч��
IS_Detail_Show = 1             ;
isShowIni = 0               ;
sigma_times = 30           ;   %���Ƴ�ʼ��sigmaֵ��meanDist�Ķ��ٱ�
DecayPram = 0.97             ;   %����sigma��ֵ�Ƿ���ѭ���иı�

[nM, ~] = size(DData);   % the number of the model point
[nN, D] = size(MData);   % the number of the test point
if D<2
    error('Demension error! Only 2D or 3D data sets are supported.');
end
if D>3
    error('Demension error! Only 2D or 3D data sets are supported.');
end
% Initialization
totaltime = 0;

% The initial value A(0)=Identity
if nargin <= 2
    if D == 2
        % 		prompt = 'ѡ�����ó�ֵ��ʽ��\n 1.�ֶ�����\n 2.Ĭ������\n';
        % 		a = input(prompt);
        a = 2;
        if a ==1
            % ginput�ȶ�MDataȡ2��ֵ���ٶ�DDataȡ2��ֵ
            disp('����ɫͼ�ϵ��������');
            [x1,y1]=ginput(2);  %%MData ��ɫ
            disp('�ں�ɫͼ�ϵ����Ӧ��������');
            [x2,y2]=ginput(2);  %%DData ��ɫ
            M1 = [x1(2)-x1(1) y1(2)-y1(1)];
            D1 = [x2(2)-x2(1) y2(2)-y2(1)];
            M1 = M1/norm(M1);
            D1 = D1/norm(D1);
            angle1 = atan2(M1(2),M1(1));
            angle2 = atan2(D1(2),D1(1));
            angle = angle2 - angle1;
            R = [cos(angle), -sin(angle); sin(angle) cos(angle)];
            clear angle1 angle2 angle
            t = (D1-(R*M1')')';
        end
        if a == 2
            R = eye(2);
            t = [0;0];
            % The method bellow to get "t" is better if there are no too many outliers.
            %             TData = (R * DData')';
            %             mX = mean(TData);
            %             mY = mean(MData);
            %             t = (mY - mX)';
        end
        clear M1 D1 a
    end
    if D == 3
        R = eye(3);
        %         TData = (R * DData')';
        %         mX = mean(TData);
        %         mY = mean(MData);
        %         t = (mY - mX)';
        t = zeros(3,1);
    end
    %     t = zeros(D,1);%tΪ������
elseif nargin <= 3
    TData = (R * DData')';
    mX = mean(TData);
    mY = mean(MData);
    t = (mY - mX)';
end

% Initialization
TotalStep = 1;  % last step, if the program is pause, it is the total iterative step
CurrStep = 1;  % current step
LastMinuserror = 10^6; %Save the last and last step's error minus last step's error
Error_of_iter(1) = 10^6;   % The Error
% To obtain the transformation data
TData = (R * DData')';
TData = TData + repmat(t',[nM,1]);
if isShowIni
    ICPPlot(TData,DData);
    title('��ֵ�趨');
end
% �����㼯�ڵ���ܼ��̶ȣ�����������ƽ������  �������Ϊ meanDist
[~,TD] = knnsearch(DData,DData,'k', 2);
meanDist = median(TD(:,2));
% �ɵ㼯���ܶȾ���sigma��ֵ
sigma1 = meanDist * sigma_times;

% �������Խ���
if IS_Detail_Show
    dotnum=1;
    fprintf('ICP_MCC is processing');
end
if IS_Step_Show == 1
    gcf_step = figure;
end
while (LastMinuserror > Epsilon && TotalStep < MaxStep)
    % while (TotalStep < MaxStep)
    tic;
    % Find the indices of closest points in the test data
    [corr, TD] = knnsearch(MData, TData);
    corr(:,2) = (1 : length(corr))';
    %     sigma1 = sigma1 * DecayPram;
    if sigma1> meanDist * 2
        sigma1 = sigma1 * DecayPram;
    end
    % Register DData with TData
    [R1, t1] = reg(TData, MData, corr,TD,sigma1);
    
    R = R1*R;
    t = R1*t + t1;
    
    % To obtain the transformation data
    TData = (R * DData')';
    TData = TData + repmat(t',[nM,1]);
    tempdistance = (TData-MData(corr(:,1), :));
    Error_of_iter(CurrStep) = sum(sum(tempdistance.^2, 2))/nM;  % compute error
    % ATTENTION: The error is cauculated based on Euclidean distance.
    
    %     if D == 2
    %         Error_of_iter2(CurrStep) = sum(exp(-(tempdistance(:,1).^2 + tempdistance(:,2).^2)/(2 * sigma1^2)))/nM;
    %     else
    %         Error_of_iter2(CurrStep) = sum(exp(-(tempdistance(:,1).^2 + tempdistance(:,2).^2 + tempdistance(:,3).^2)/(2 * sigma1^2)))/nM;
    %     end
    % ATTENTION: The error is cauculated based on correntropy.
    
    TotalStep = CurrStep;     % TotalStep record current step as last step
    CurrStep = CurrStep + 1;  % CurrStep is next step
    
    if TotalStep == 1
        LastMinuserror = Error_of_iter(TotalStep);
    else
        LastMinuserror = abs(Error_of_iter(TotalStep) - Error_of_iter(TotalStep-1));
    end
    
    if IS_Detail_Show && ((TotalStep/10)>dotnum)
        fprintf('.');
        dotnum = dotnum + 1;
    end
    passtime = toc;
    %   disp(['Complete ', num2str(TotalStep),  ' time, ', 'take ', num2str(passtime), 's' ]);
    totaltime = totaltime + passtime;
    if IS_Step_Show == 1;
        clf(gcf_step);
        ICPPlot(TData,MData,gcf_step);
        view(0,90);
        title(['��',num2str(CurrStep),'֡'])
        pause(0.001);
    end
end
if IS_Step_Show == 1;
    close(gcf_step);
end
if IS_Detail_Show
    fprintf('\n');
    disp(['Complete ', num2str(TotalStep),  ' times']);
end
disp(['Totaltime: ', num2str(totaltime), 'S' ]);
if IS_Detail_Show
    disp(['Sigma:',num2str(sigma1)]);
end
% figure;
% plot(fals, 'r-');

%-----------------------------------------------------------------
%%%%%%%%%%%%%% T(TData)->DData %%%%%%%%%%%%%%%%
function [R1, t1] = reg(TData,DData,corr,TD,sigma)
n = length(corr);
[~,D] = size(TData);
% sigma = 1;
G = exp(-(TD.^2)/(2*sigma^2));
% Dg = diag(G);

X = TData(corr(:,2),:);
Y = DData(corr(:,1),:);
sum_G = sum(G);
mX = (X'*G/sum_G)';
mY = (Y'*G/sum_G)';
% for i = 1:n
% mX = mX + G(i)*X(i,:);
% mY = mY + G(i)*Y(i,:);
% end
% mX = mX/sum_G;
% mY = mY/sum_G;

Xshifted = X - repmat(mX,[n,1]);
Yshifted = Y - repmat(mY,[n,1]);
% To get the rotation matrix
Xshifted(:,1) = Xshifted(:,1) .* G;
Xshifted(:,2) = Xshifted(:,2) .* G;
if D>2
    Xshifted(:,3) = Xshifted(:,3) .* G;
end
K = Xshifted'*Yshifted;
K = -sigma^(-2)*K/n;        %�����n���Ƶ���û������

[U,~,V] = svd(K);
R1 = V*U';

% if det(R1)<0
%     D = eye(3);
%     D(3,3) = -1;
%     R1 = R1*D;
% end

R1 = R1*(-eye(D));          %��֪��ΪʲôҪ�� û���κε���

t1 = (Y' - R1*X')*G/sum_G;
