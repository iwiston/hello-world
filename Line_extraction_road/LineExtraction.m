%%%%%%%%%%%%%%%%%%%%%%%%%% Script LineExtraction  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This program is used to extract line segment from road center line
% 
%
% Author: 
% Create Date: 2020-07-25
% =======update=======
% 1.
%======== to do list ============
% 1. 
% 
% Processing Flow:
%       
% Notes:
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Steps:
% 1. Create some dummy test paths or load data

clear all
close all

load('PM2SC_ENU.mat')
load('SC2PM_ENU.mat')
addpath('curvature')
figure(1);
clf;
hold on;
grid minor;
plot(PM2SC_ENU(:,1),PM2SC_ENU(:,2),'b.')
% plot(SC2PM_ENU(:,1),SC2PM_ENU(:,2),'b.')

% step 2: interpolation of reference
PM2SC_ENU = unique(PM2SC_ENU,'rows'); % remove the repeat points

PM2SC_ENU_station = [0; cumsum(sqrt(sum(diff(PM2SC_ENU).^2,2)))];
resolution = 10; % units, meter
nb_query = round(PM2SC_ENU_station(end)/resolution+1); %how many points we need to query on the interpolation curve

% PM2SC_ENU = unique(PM2SC_ENU(:,2),'rows');
% PM2SC_ENU = unique(PM2SC_ENU(:,3),'rows');
PM2SC_ENU_inter = fcn_interparc(nb_query,PM2SC_ENU(:,1),PM2SC_ENU(:,2),PM2SC_ENU(:,3),'pchip');
PM2SC_ENU_inter_station = [0; cumsum(sqrt(sum(diff(PM2SC_ENU_inter).^2,2)))];
plot(PM2SC_ENU_inter(:,1),PM2SC_ENU_inter(:,2),'r.')
xlabel('xEast')
ylabel('yNorth')
text(PM2SC_ENU_inter(1,1),PM2SC_ENU_inter(1,2),'\leftarrow Start','FontSize',14)
axis equal
PM2SC_ENU_inter = sortrows(PM2SC_ENU_inter); %%% be careful, nned to remove later

%% step3 line segment extraction
flag_method = 2; % 1, convert scattter point into image and use Hough tansform
% 2, Since our data is road like curve,rather than random
%    distribution, so we can analysis the curvature.(for noisy data, some preprocess may be required)
%%method 1 . convert it to image and extract the line using Hough tansform
if flag_method ==1
    % 1. convert the point clould to image
    I = pointcloud2image(ones(size(PM2SC_ENU_inter(:,3))),PM2SC_ENU_inter(:,1),PM2SC_ENU_inter(:,2),512,512 );
    I(I<1)=0;
    figure(2);
    clf
    imshow(I,[]);
    
    %2. Hough tansform
    
    % BW = edge(I,'canny');
    BW = imcomplement(I);
    figure(2154);
    clf
    imshow(BW,[]);
    
    [H,T,R] = hough(BW);
    figure(3);
    imshow(H,[],'XData',T,'YData',R,...
        'InitialMagnification','fit');
    xlabel('\theta'), ylabel('\rho');
    axis on, axis normal, hold on;
    
    % Find peaks in the Hough transform of the image.
    % P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    x = T(P(:,2)); y = R(P(:,1));
    plot(x,y,'s','color','white');
    
    % Find lines and plot them.
    
    lines = houghlines(BW,T,R,P,'FillGap',2,'MinLength',5);
    figure(4)
    clf
    imshow(I), hold on
    max_len = 0;
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
        
        % Plot beginnings and ends of lines
        plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','b');
        plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
        
        % Determine the endpoints of the longest line segment
        len = norm(lines(k).point1 - lines(k).point2);
        if ( len > max_len)
            max_len = len;
            xy_long = xy;
        end
    end
    
elseif flag_method ==2
    % find curvature of cuvre
    flag_dataDimension = 2; %3 means 3D data (X,Y,Z), 2 means 2 D data(X,Y)
    
    switch flag_dataDimension
        case 3
            [L,R,K] = curvature(PM2SC_ENU_inter);
        case 2
            [L,R,K] = curvature(PM2SC_ENU_inter(:,1:2));
            
            make_plot = 0; %parameter of fnc_parallel_curve
            flag1 =0; %parameter of fnc_parallel_curve
            smooth_size = 0; %parameter of fnc_parallel_curve
            [~, ~, ~, ~,Radius,UnitNormalV]=fnc_parallel_curve(PM2SC_ENU_inter(:,1),PM2SC_ENU_inter(:,2), 3, make_plot,flag1,smooth_size);
            
        otherwise
            warning('Unexpected data dimension. No plot created.')
    end
    
    figure(2212);
    plot(L,R,'b')
    xlabel station
    ylabel('Curvature radius')
    title('Curvature radius vs. station')
    ylim([0 10000])
    
    figure(22712);
    plot(PM2SC_ENU_inter_station,Radius,'r.')
    xlabel station
    ylabel('Curvature radius')
    title('Curvature radius vs. station')
    ylim([0 100000])
    
    % find the segment whcih can be considered as a line
    R_theshold = 4000;
    line_index = find(Radius>R_theshold);
    line_index_diff = diff(line_index);
    line_start =[1; find(line_index_diff>1)];
    for i_line= 1:(length(line_start)-1)
        line_segment.points = PM2SC_ENU_inter(line_index(line_start(i_line)+1:line_start(i_line+1)),:);
        line_segment.strat_point = PM2SC_ENU_inter(line_start(i_line),:);
        line_segments(i_line) = line_segment;
    end
    
    figure(2324325)
    clf
    hold on
    plot(PM2SC_ENU_inter(:,1),PM2SC_ENU_inter(:,2),'r')
    plot(PM2SC_ENU_inter(line_index,1),PM2SC_ENU_inter(line_index,2),'b.')
    for i= 1:length(line_segments)
        plot(line_segments(i).points(:,1),line_segments(i).points(:,2),'bo')
    end
    xlabel('xEast')
    ylabel('yNorth')
    text(PM2SC_ENU_inter(1,1),PM2SC_ENU_inter(1,2),'\leftarrow Start','FontSize',14)
    axis equal
    
end