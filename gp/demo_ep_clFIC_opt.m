function demo_ep_clFIC_opt
%DEMO_CLAASIFIC1    Classification problem demonstration for 2
%                 classes with EP and using optmization for parameters.
%
%      Description
%      The demonstration program is based on synthetic two 
%      class data used by B.D. Ripley (Pattern Regocnition and
%      Neural Networks, 1996}. The data consists of 2-dimensional
%      vectors that are divided into to classes, labeled 0 or 1.
%      Each class has a bimodal distribution generated from equal
%      mixtures of Gaussian distributions with identical covariance
%      matrices. A Bayesian aprouch is used to find the decision
%      line and predict the classes of new data points.

% Copyright (c) 2007 Jarno Vanhatalo, Jaakko Riihim�ki

% This software is distributed under the GNU General Public 
% License (version 2 or later); please refer to the file 
% License.txt, included with the software, for details.

% This demonstration is based on the dataset used in the book Pattern Recognition and
% Neural Networks by B.D. Ripley (1996) Cambridge University Press ISBN 0 521
% 46986 7

disp(' ')
disp(' The demonstration program is based on synthetic two ')
disp(' class data used by B.D. Ripley (Pattern Regocnition and')
disp(' Neural Networks, 1996}. The data consists of 2-dimensional')
disp(' vectors that are divided into to classes, labeled 0 or 1.')
disp(' Each class has a bimodal distribution generated from equal')
disp(' mixtures of Gaussian distributions with identical covariance')
disp(' matrices. A Gaussian process is used to find the decision')
disp(' line and predict the classes of new data points.')
disp(' ')
disp(' ')

  
% Load the data
S = which('demo_clFull');
L = strrep(S,'demo_clFull.m','demos/synth.tr');
x=load(L);

% Set the targets to {-1,1}. NOTE! Compare with logistic with which we need {0,1}.
y=x(:,end);
y=y*2-1;
x(:,end)=[];
[n, nin] = size(x);

disp(' ')
disp(' First we create a Gaussian process for classification problem. ')
disp(' A Gaussian multivariate hierarchical prior with ARD is created')
disp(' for GP. ')
disp(' ')

% Create covariance functions
% Create covariance functions
gpcf1 = gpcf_sexp('init', nin, 'lengthScale', 1, 'magnSigma2', 0.2^2);
%gpcf1 = gpcf_sexp('init', nin, 'lengthScale', [1 1], 'magnSigma2', 0.2^2);

%gpcf1 = gpcf_exp('init', nin, 'lengthScale', 1, 'magnSigma2', 0.2^2);
%gpcf1 = gpcf_exp('init', nin, 'lengthScale', [1 1], 'magnSigma2', 0.2^2);

%gpcf1 = gpcf_matern32('init', nin, 'lengthScale', 1, 'magnSigma2', 0.2^2);
%gpcf1 = gpcf_matern32('init', nin, 'lengthScale', [1 1], 'magnSigma2', 0.2^2);

%gpcf1 = gpcf_matern52('init', nin, 'lengthScale', 1, 'magnSigma2', 0.2^2);
%gpcf1 = gpcf_matern52('init', nin, 'lengthScale', [1 1], 'magnSigma2', 0.2^2);

% Set the prior for the parameters of covariance functions 
gpcf1.p.lengthScale = gamma_p({3 7 3 7});
gpcf1.p.magnSigma2 = sinvchi2_p({0.05^2 0.5});


% $$$ [u1,u2]=meshgrid(linspace(-1.25, 0.9,6),linspace(-0.2, 1.1,6));
% $$$ U=[u1(:) u2(:)];
% $$$ U = U([3 4 7:18 20:24 26:30 33:36],:);
% $$$ U = U(1:2:end,:);

[u1,u2]=meshgrid(linspace(-1.25, 0.9,6),linspace(0.2, 0.8,2));
U=[u1(:) u2(:)];

figure(1)
plot(x(:,1), x(:,2),'*'), hold on
plot(U(:,1), U(:,2), 'kX', 'MarkerSize', 12, 'LineWidth', 2)

% Initiliaze the likelihood
likelih = likelih_probit('init', y);

% Initialize the GP
gp = gp_init('init', 'FIC', nin, likelih, {gpcf1}, []);
gp = gp_init('set', gp, 'X_u', U);
gp.ep_opt.display = 1;
gp = gp_init('set', gp, 'latent_method', {'EP', x, y, 'hyper'});
%gp = gp_init('set', gp, 'latent_method', {'EP', x, y, 'all'});

% $$$ [e, edata, eprior] = gpep_e(gp_pak(gp,'hyper'), gp, x, y, 'hyper')
% $$$ [g, gdata, gprior] = gpep_g(gp_pak(gp,'hyper'), gp, x, y, 'hyper')
% $$$ gradcheck(gp_pak(gp,'all'), @gpep_e, @gpep_g, gp, x, y, 'all')
gradcheck(gp_pak(gp,'hyper'), @gpep_e, @gpep_g, gp, x, y, 'hyper')

disp(' ')
disp(' Find the point estimates for the parameters with early stop method. ')
disp(' ')

w=gp_pak(gp,'all');

fe=str2fun('gpep_e');
fg=str2fun('gpep_g');
n=length(y);
% $$$ optes=scges_opt;
% $$$ optes.display=1;
% $$$ optes.tolfun=3e-1;
% $$$ optes.tolx=1e-1;
opt(1) = 1;
opt(2) = 1e-2;
opt(3) = 3e-1;
opt(9) = 0;
opt(10) = 0;
opt(11) = 0;
opt(14) = 0;

% do scaled conjugate gradient optimization with early stopping.
gp.ep_opt.display = 1;
[w, opt, flog]=scg2(fe, w, opt, fg, gp, x, y, 'all');
gp=gp_unpak(gp,w,'all');


% Print the hyperparameter values
fprintf(' The point estimate of length-scale is: %.3f \n The point estimate of magnitude sigma is: %.3f \n',...
        gp.cf{1}.lengthScale, gp.cf{1}.magnSigma2)

% Print some figures that show results
xt1=repmat(linspace(min(x(:,1)),max(x(:,1)),20)',1,20);
xt2=repmat(linspace(min(x(:,2)),max(x(:,2)),20)',1,20)';
xstar=[xt1(:) xt2(:)];

[Ef, Varf, p1] = ep_pred(gp, x, y, xstar, 'all');

% visualise predictive probability  p(ystar = 1)
figure, hold on;
n_pred=size(xstar,1);
h1=pcolor(reshape(xstar(:,1),20,20),reshape(xstar(:,2),20,20),reshape(p1,20,20))
set(h1, 'edgealpha', 0), set(h1, 'facecolor', 'interp')
colormap(repmat(linspace(1,0,64)', 1, 3).*repmat(ones(1,3), 64,1))
axis([-inf inf -inf inf]), axis off
plot(x(y==-1,1),x(y==-1,2),'o', 'markersize', 8, 'linewidth', 2);
plot(x(y==1,1),x(y==1,2),'rx', 'markersize', 8, 'linewidth', 2);
plot(gp.X_u(:,1), gp.X_u(:,2), 'gx', 'MarkerSize', 12, 'LineWidth', 2)
set(gcf, 'color', 'w'), title('predictive probability and training cases', 'fontsize', 14)

% Visualize the predictive variance
figure, hold on;
n_pred=size(xstar,1);
h1=pcolor(reshape(xstar(:,1),20,20),reshape(xstar(:,2),20,20),reshape(Varf,20,20))
set(h1, 'edgealpha', 0), set(h1, 'facecolor', 'interp')
colormap(repmat(linspace(1,0,64)', 1, 3).*repmat(ones(1,3), 64,1))
axis([-inf inf -inf inf]), axis off
plot(x(y==-1,1),x(y==-1,2),'o', 'markersize', 8, 'linewidth', 2);
plot(x(y==1,1),x(y==1,2),'rx', 'markersize', 8, 'linewidth', 2);
plot(gp.X_u(:,1), gp.X_u(:,2), 'gx', 'MarkerSize', 12, 'LineWidth', 2)
set(gcf, 'color', 'w'), title('marginal predictive latent variance', 'fontsize', 14)

% visualise predictive probability  p(ystar = 1) with contours
figure, hold on
[cs,h]=contour(reshape(xstar(:,1),20,20),reshape(xstar(:,2),20,20),reshape(p1,20,20),[0.025 0.25 0.5 0.75 0.975], 'linewidth', 3);
text_handle = clabel(cs,h);
set(text_handle,'BackgroundColor',[1 1 .6],'Edgecolor',[.7 .7 .7],'linewidth', 2, 'fontsize',14)
c1=[linspace(0,1,64)' 0*ones(64,1) linspace(1,0,64)'];
colormap(c1)
plot(x(y==1,1), x(y==1,2), 'rx', 'markersize', 8, 'linewidth', 2),
plot(x(y==-1,1), x(y==-1,2), 'bo', 'markersize', 8, 'linewidth', 2)
plot(xstar(:,1), xstar(:,2), 'k.'), axis([-inf inf -inf inf]), axis off
set(gcf, 'color', 'w'), title('predictive probability contours with training cases', 'fontsize', 14)

% test how well the network works for the test data. 
L = strrep(S,'demo_clFull.m','demos/synth.ts');
tx=load(L);
ty_temp=tx(:,end);
ty = 2*ty_temp-1;
tx(:,end)=[];

[Eftest, Varftest, p1test] = ep_pred(gp, x, y, tx, 'all');

% calculate the percentage of misclassified points
missed = sum(abs(round(p1test)-ty_temp))/size(ty,1)*100

% Plot the training and test cases in the same figure
figure, hold on;
c1=[linspace(0,1,64)' 0*ones(64,1) linspace(1,0,64)'];
colormap(c1)
plot(x(y==-1,1),x(y==-1,2),'o', 'markersize', 8, 'linewidth', 2);
plot(x(y==1,1),x(y==1,2),'rx', 'markersize', 8, 'linewidth', 2);
plot(tx(ty==-1,1),tx(ty==-1,2),'go', 'markersize', 8, 'linewidth', 2);
plot(tx(ty==1,1),tx(ty==1,2),'cx', 'markersize', 8, 'linewidth', 2);
plot(xstar(:,1), xstar(:,2), 'k.'), axis([-inf inf -inf inf]), axis off
set(gcf, 'color', 'w'), title('training and test cases', 'fontsize', 14)

% visualise predictive probability  p(ystar = 1) with the test cases
figure, hold on;
n_pred=size(xstar,1);
h1=pcolor(reshape(xstar(:,1),20,20),reshape(xstar(:,2),20,20),reshape(p1,20,20))
set(h1, 'edgealpha', 0), set(h1, 'facecolor', 'interp')
colormap(repmat(linspace(1,0,64)', 1, 3).*repmat(ones(1,3), 64,1))
axis([-inf inf -inf inf]), axis off
plot(tx(ty==-1,1),tx(ty==-1,2),'o', 'markersize', 8, 'linewidth', 2);
plot(tx(ty==1,1),tx(ty==1,2),'rx', 'markersize', 8, 'linewidth', 2);
set(gcf, 'color', 'w'), title('predictive probability and test cases', 'fontsize', 14)

