% Search.Method=1 constant_K
% Search.Method=2 Adaptive_K

% For 3 and 4 dimension problem 2018 December 

clear all; close all; clc
% global n m ms bnd1 bnd2 Ain bin acon Search r xi tri
global n m ms bnd1 bnd2  Search  Ain bin tri MESH_SIZE iter_max
% Search.constant=0;
%
% n=2;
% for InitNum = ['one', 'tre'] 

% for n = 2:4
n= 3; 
ms=1;
RES = 5e-2;
x_star=ones(n,1) *0.153;
% x_star=ones(n,1) *0.46;

%
Method = 2;
%
x0=zeros(n,1); KCf = 1; KC2 = 1;

fun=@(x)  sum((x-x0).^2)*4; Var = 4*0.024*n;

con{1}=@(x) (4*rastriginn2(x,n)-n )*KC2; 



% fun=@(x) ( (x(1,:)-x0(1)).^2+(x(2,:)-x0(2)).^2 +(x(3,:)-x0(3)).^2 )*KCf;
% fun=@(x) ( (x(1,:)-x0(1)).^2+(x(2,:)-x0(2)).^2 + (x(4,:)-x0(4)).^2 +(x(3,:)-x0(3)).^2 )*KCf;
% fun=@(x) ( (x(1,:)-x0(1)).^2+(x(2,:)-x0(2)).^2 )*KCf;
% constraint = @(x,n) rastriginn2(x);
% con{1}=@(x) (sum(4*(x-0.7).^2-2*cos(2*pi*(x-0.7)))-1/12)/n;
% con{1}=@(x) (constraint(x)-n/4 )*KC2/n; %the same
% con{1}=@(x) (rastriginn2_b(x))*KC2; %the same
% con{1}=@(x) (rastriginn2_paper(x,n)-0.5*n )*KC2; 
% con{1}=@(x) (rastriginn2(x)-0.5*n )*KC2; %the for n problems 
% Var = 0.0721;
% Var=fun(x_star); %+1e-3
% Var = 0.024;

% Var = 0.023;

%
MESH_SIZE=8; % grid size% % Mss=20;
% interpolaion strategy
inter_method=1;

% Calculate the initial points

% InitNum = 'one'; % bad initializaiton 
% InitNum = 'two'; %
% InitNum = 'tre'; % good initialization
% % if InitNum == 'one'
 %      InitNum = 'tre';
InitNum = 'tre';

if InitNum == 'one'
xE=ones(n ,1)*0.45;
delta0=0.15; 
elseif InitNum == 'two'
    xE=ones(n,1)*0.6;
    delta0=0.15;
elseif InitNum == 'tre'
    xE=ones(n,1)*0.3;
    delta0=0.15;
end

for ii=1:n
    e=zeros(n,1); e(ii)=1;
    xE(:,ii+1)=xE(:,1)+delta0*e;
end
% calculates acon , yi, C
lob=zeros(n,1); upb=ones(n,1);
Search.method = Method;
Search.constant = Var;
bnd1 = lob;
bnd2 = upb;
xU=bounds(bnd1,bnd2, n);
% Input the equality constraints
Ain=[eye(n);-eye(n)];
bin=[bnd2 ;-bnd1];
% Calculate the function evaluation at initial points
for ii=1:ms
    acon{ii}=[];
end
for ii=1:size(xE,2)
    ind=1:2*n;
    ind=ind(Ain*xE(:,ii)-bin>-0.01);
    for jj=1:length(ind)
        acon{ind(jj)}=[acon{ind(jj)} ii];
    end
    yE(ii)=fun(xE(:,ii));
    for jj=1:ms
        C{jj}(ii)=con{jj}(xE(:,ii));
    end
end
x_prev = xE(:,1);
y_prev = yE(:,1);
delta_tol=0.2;

%
iter_max = 300;
y0=Search.constant;

for kkk=1:9
    for k=1:iter_max
        %             save surr_pts_2 yi xi C tri acon
        disp( [' started iteration ' ,num2str(k), ' ... ', 'with number func. eval = ',num2str(size(xE,2))] )
        tri=delaunayn([xE xU].');
         xi=[xE xU];
        
        %%%%%%%%%%% Modify the interpolations %%%%%%%%%%%%%%%%%%%
        inter_par_p= interpolateparametarization(xE,yE,inter_method);
        for jj=1:ms
            inter_par_g{jj}= interpolateparametarization(xE,C{jj},inter_method);
        end
        
        %%%%%%%%% Calculate Discrete search function %%%%%%%%%%%
        yup=zeros(1,size(xU,2));
        for ii=1:size(xU,2)
            yup(ii)=estimate_max_cons_val(xU(:,ii),inter_par_p,inter_par_g,y0,ms)/mindis(xU(:,ii),xE);
%             yup(ii)=inf;
        end
        
        % Perform the search
        while 1
%              keyboard
            [xm ym(k) Cs(k) indm2]= ...
                tringulation_search_constraints(inter_par_p,inter_par_g,[xE xU], tri)
            %keyboard
            xm=round((xm-bnd1)./(bnd2-bnd1).*MESH_SIZE)./MESH_SIZE.*(bnd2-bnd1)+bnd1;
            
            [xm,xE,xU,newadd,success]=...
                points_neighbers_find(xm,xE,xU);
            
            if success==1
                break
            else
                yup=[yup estimate_max_cons_val(xm,inter_par_p,inter_par_g,y0,ms)/mindis(xm,xE)];
            end
        end
        
%                        % stopping criteria
%         if mindis(xm,[xE xU])<1e-6
%             break
%         end


%         evaluating step
        if (estimate_max_cons_val(xm,inter_par_p,inter_par_g,y0,ms)/mindis(xm,xE)>min(yup) )
            [t,ind]=min(yup);
            xm=xU(:,ind); xU(:,ind)=[];
%         end
        %         evaluating step
        elseif  (mindis(xm,xU)<1e-6 && mindis(xm,xU)~=Inf)
            [t,ind]=min(yup);
            xm=xU(:,ind); xU(:,ind)=[];
        end
        



%         % feasible constraint projection
%         if mindis(xm,[xE xU])<1e-6
%             break
%         end
       
        
      %        identifying step
        if mindis(xm,xE)<1e-6
            break
        end
        
        % Perform the function evalutions
        %     Evaluated set
        xE=[xE xm];
        yE = [yE fun(xm)];
        for jj=1:ms
            C{jj}=[C{jj} con{jj}(xm)];
        end
 
       %
        if Search.method ==2
            figure(11);
            subplot(2,1,1)
            plot(yE-Var)
            subplot(2,1,2)
            plot(max(yE-Var, C{1}))

        end
        
         if min(max(yE-Var, C{1}))<= RES
        
%                             if norm(xm-x_star)<RES
                resFile = strcat('results_OmegaZ_paper_init_', InitNum, '_n_', num2str(n),'_new.mat');
                save(resFile)

                        if n==2
 h=figure(2); clf;
%    tri=delaunayn(xi.');
%     triplot(tri,xi(1,:),xi(2,:))
    hold on
   tt=0:0.01:1;
for ii=1:length(tt)
    for jj=1:length(tt)
        U(ii,jj)=con{1}([tt(jj) ;tt(ii)])-3.11;
    end
end
contourf(tt,tt,U,0:3.11:3.11)
colormap gray
% colormap bone
brighten(0.5)
%     end
strmax = ['   ', num2str(k)];
% text(xi(1,:),xi(2,:),strmax ,'HorizontalAlignment','right');
    plot(xE(1,1:n+1),xE(2,1:n+1),'ks',  'MarkerFaceColor','b', 'MarkerSize',  15) 
      plot(xE(1,:),xE(2,:),'rs', 'MarkerSize', 15) 
     plot(xU(1,:),xU(2,:),'b*', 'MarkerSize', 18) 
                 plot(x_star(1),x_star(2),'kp','MarkerFaceColor','b', 'MarkerSize', 18)
                triplot(tri,xi(1,:),xi(2,:)) 
            drawnow
            end

%                      keyboard
break
            end
        
%                      % stopping criteria
%         if mindis(xm,[xE xU])<1e-6
%             break
%         end
        
        iplot_check=0;
        if iplot_check==1
            clear U_f p_f G_c C_l Err TT SS G1 G2 xi
            xi=[xE xU];
            xv=0:0.01:1;
            for ii=1:length(xv)
                for jj=1:length(xv)
                    %         U_f(ii,jj)=fun([xv(ii) ;xv(jj)]);
                    P_f(ii,jj)=interpolate_val([xv(ii) ;xv(jj)],inter_par_p);
                    C_l(ii,jj)=con{1}([xv(ii) ;xv(jj)]);
                    %         G_c(ii,jj)=interpolate_val([xv(ii) ;xv(jj)],inter_par_g{1});
                    G1=interpolate_val([xv(ii) ;xv(jj)],inter_par_g{1});
                    G2=interpolate_val([xv(ii) ;xv(jj)],inter_par_g{2});
                    [Err(ii,jj),TT(ii,jj),SS(ii,jj)] = direct_uncer([xv(ii) ;xv(jj)],xi,inter_par_p,inter_par_g,tri);
                    CC(ii,jj) = max([G1, G2])- Search.constant * Err(ii,jj);
                    %          CC_2(ii,jj) = max([G1, G2])- Search.constant * Err(ii,jj);
                    % %        if CC(ii,jj) >0
                    % % %            CC(ii,jj) = nan;
                    % % CC(ii,jj) = 0;
                    % %        else
                    % %            CC(ii,jj) = 1;
                    % %        end
                    
                    
                end
            end
            %
            % h=figure; clf;
            % ah(1) = axes('Position', [0.015 0.48 0.3 0.47]);
            figure(10); clf;
            axis square
            box on
            hold on
            contourf(xv,xv,-CC.', 0:10:10,  'linestyle', 'none' );
            grid on
            grid minor
            plot(x_star(1),x_star(2),'kp','MarkerFaceColor','b', 'MarkerSize', 18)
            brighten(0.5)
            colormap('bone')
            % colorbar
            % caxis([-.010,0])
            % contourf(xv,xv,(CC).')
            % contourf(xv,xv,(CC).','linestyle', 'none',0.1:0.1)
            % set(h,'linestyle','none');
            % caxis([-0.0001,0.0001])
            % colormap(map)
            %
            %   plot(xi(1,:),xi(2,:),'ro', 'MarkerSize', 13)
            if Ex ==1
                plot(tt, b*sin(pi*tt), 'k', 'linewidth', 3)
            elseif Ex==2
                plot(tt, con{1}(tt), 'k', 'linewidth', 3)
            end
            %% plot the evaluated points
%             plot(xi(1,1:4),xi(2,1:4),'ks',  'MarkerFaceColor','k','MarkerSize', 15)
%             plot(xi(1,5:end),xi(2,5:end),'ks','MarkerFaceColor','k', 'MarkerSize', 15)
            
            plot(xi(1,1:4),xi(2,1:4),'ks',  'MarkerFaceColor','k','MarkerSize', 15)
            plot(xi(1,5:end),xi(2,5:end),'ks','MarkerFaceColor','k', 'MarkerSize', 15)
            %   plot(xi(1,4:end-1),xi(2,4:end-1),'ro', 'MarkerSize', 13)
            plot(xi(1,end),xi(2,end),'wx', 'MarkerSize', 15)            
            % caxis([-0.5,0])
            % colorbar
            % title(['iter = ', num2str(k)], 'FontSize', 20)
            % title('max (g_l(x) - K e(x))')
            % axis off
            set(gca, 'ytick', [])
            set(gca, 'xtick', []) 
            drawnow
            

        end        
        %% stoping 
        disp([num2str(k/iter_max*100), ' % Completed'])
        
        
        

    end
    
%     keyboard
    MESH_SIZE=MESH_SIZE*2;
end

stat.test = InitNum;
stat.bndpt = sum(min(xE)<0.01 | max(xE)>0.99);
stat.support = size(xU,2);
stat.n = n;
stat.meshrefinement = kkk;
stat.NumfEval = size(xE,2);

                resFile = strcat('results_OmegaZ_stat_', InitNum, '_n_', num2str(n),'_new2.mat');
                save(resFile)
% end
% end

%%
    %%
% save results_OmegaZ_paper4D.mat
disp('initial point &  \# of Func. Eval.  &  \# of support points &  \# of boundary points \n')
fprintf(' %s & %d &  & %d  & %d & %d   \n ',InitNum, n, stat.NumfEval,  stat.support,  stat.bndpt);
% 
