% bc_wl_timeseries_and_maps.m
% Panels for BC (boundary coupling) & WL/LOCP flows + biomass & rainfall
% Figures:
%   (1) Time series: Rainfall + Biomass + BC (SC/FC water & nitrogen)
%   (2) Time series: Rainfall + Biomass + WL/LOCP (SC/FC water & nitrogen)
%   (5) Maps: BC water (SC, FC)
%   (6) Maps: BC nitrogen (SC, FC)
%   (7) Maps: WL/LOCP water (SC, FC)
%   (8) Maps: WL/LOCP nitrogen (SC, FC)

clearvars; close all; clc;

%% ----------------------------- Paths -----------------------------------
ROOT     = fileparts(mfilename('fullpath'));
DATA_DIR = ROOT;                 % change if mats are elsewhere
OUT_DIR  = fullfile(ROOT,'figs'); if ~exist(OUT_DIR,'dir'), mkdir(OUT_DIR); end
SAVE_FIG = false;                % <- set true to save .tiff

%% --------------------------- Load data ---------------------------------
load(fullfile(DATA_DIR,'data_rain_graze_ss_m17.mat'), 'data_rain_graze_ss_m17');

% BC (Boundary Coupling), WL/LOCP (local pass) — nodewise [r,g,time,10000]
load(fullfile(DATA_DIR,'BC_SC_water.mat'),      'BC_SC_water');
load(fullfile(DATA_DIR,'BC_FC_water.mat'),      'BC_FC_water');
load(fullfile(DATA_DIR,'BC_SC_nitrogen.mat'),   'BC_SC_nitrogen');
load(fullfile(DATA_DIR,'BC_FC_nitrogen.mat'),   'BC_FC_nitrogen');

load(fullfile(DATA_DIR,'LOCP_SC_water.mat'),    'LOCP_SC_water');
load(fullfile(DATA_DIR,'LOCP_FC_water.mat'),    'LOCP_FC_water');
load(fullfile(DATA_DIR,'LOCP_SC_nitrogen.mat'), 'LOCP_SC_nitrogen');
load(fullfile(DATA_DIR,'LOCP_FC_nitrogen.mat'), 'LOCP_FC_nitrogen');

% Rain
load(fullfile(DATA_DIR,'raindata.mat'),      'raindata');
load(fullfile(DATA_DIR,'scaled_series.mat'), 'scaled_series');
raindataup = [raindata(2,:); scaled_series; raindata(3,:)];

%% ---------------------------- Factors ----------------------------------
% rainfall indices for plotting (Dry=1, Wet=9) & model indices (Dry=1, Wet=4)
R_rain   = [1 9];
R_model  = [1 4];
Graz     = [1 2 5 8];                      % 1 g, 30%, 45%, 60%
graz_lbl = {'1 g','30%','45%','60%'};
clim_lbl = {'Dry Endmember','Wet Endmember'};

xTicks   = [1 6:20:126];
xTickLbl = {'1895','1900','1920','1940','1960','1980','2000','2020'};
gColors  = jet(4);

% Time slices for maps (your 8 snapshots)
timeperiod = [46 51 71 91 111 131 151 171] - 44; % -> 1..128 index space
time_lbl   = {'1895','1900','1920','1940','1960','1980','2000','2020'};

%% ----------------------- Small helpers ---------------------------------
get_avg_biomass = @(plant) deal( ...
  squeeze(mean(mean( plant(47:end,11:110,11:110,1),3,'omitnan'),2,'omitnan'))', ...
  squeeze(mean(mean( plant(47:end,11:110,11:110,2),3,'omitnan'),2,'omitnan'))' );

avg_nodes = @(A) squeeze(mean(A,4));   % [r,g,time,10000] -> [r,g,time]

save_tiff = @(fig, base) ...
  (SAVE_FIG && print(fig, fullfile(OUT_DIR,[base '.tiff']), '-dtiff','-r300'));

doe_name = @(varargin) strjoin( ...
  arrayfun(@(i) lower(string(varargin{2*i-1})+"-"+regexprep(string(varargin{2*i}),'\s+','')), ...
           1:(numel(varargin)/2), 'UniformOutput',false), '_');

%% ============================= FIGURE 1 =================================
% Time series: Rain + Biomass + BC (SC/FC water & nitrogen)
for r = 1:2
  fig = figure(r); clf; set(fig,'Color','w','WindowState','maximized');

  % a) Rain
  subaxis(6,1,1,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025);
  plot(raindataup(R_rain(r),:),'-k','LineWidth',1.5); axis tight; xlim([0.5 128.5]);
  legend('annual rainfall (subplot a)','Location','northwest','Box','off'); legend('boxoff');
  title(clim_lbl{r});
  ylabel('Rainfall (mm)'); set(gca,'FontSize',9); xticks(xTicks); xticklabels(''); box on;

  % b) Biomass (mean over 100x100)
  subaxis(6,1,2,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025); hold on;
  for g = 1:4
    sim   = data_rain_graze_ss_m17{R_model(r), Graz(g), 1};
    plant = sim{1,1};
    [avgG, avgS] = get_avg_biomass(plant);
    plot(avgG,'-o','LineWidth',1.2,'MarkerSize',3,'Color',gColors(g,:));
    plot(avgS,'-x','LineWidth',1.2,'MarkerSize',5,'Color',gColors(g,:));
  end
  axis tight; xlim([0.5 128.5]); ylim([0 59]); yticks(15:15:45);
  ylabel('Biomass (g/m^2)'); set(gca,'FontSize',9); xticks(xTicks); xticklabels('');
  legend('grass (subplot b)','shrub (subplot b)','Orientation','horizontal','Box','off');

  % c–f) BC time series (node-average to scalar)
  BC_SCw = avg_nodes(BC_SC_water);   % [r,g,time]
  BC_FCw = avg_nodes(BC_FC_water);
  BC_SCn = avg_nodes(BC_SC_nitrogen);
  BC_FCn = avg_nodes(BC_FC_nitrogen);

  panel = {@() ylabel('BC SC water'), @() ylabel('BC FC water'), ...
           @() ylabel('BC SC nitrogen'), @() ylabel('BC FC nitrogen')};
  series = {@() squeeze(BC_SCw(r,:,:)), @() squeeze(BC_FCw(r,:,:)), ...
            @() squeeze(BC_SCn(r,:,:)), @() squeeze(BC_FCn(r,:,:))};
  ylims  = {[0 11e5], [0 11.5e5], [0 11e5], [0 17e5]};

  for p = 1:4
    subaxis(6,1,2+p,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025); hold on;
    S = series{p}();                        % time x grazing(=4)
    for g = 1:4, plot(S(:,g), 'LineWidth',1.5,'Color',gColors(g,:)); end
    axis tight; xlim([0.5 128.5]); set(gca,'FontSize',9);
    if ~isempty(ylims{p}), ylim(ylims{p}); end
    panel{p}(); xticks(xTicks);
    if p < 4, xticklabels(''); else, xticklabels(xTickLbl); xlabel('Time (years)'); end
    if p == 4
      legend('1 g (c–f)','30% (c–f)','45% (c–f)','60% (c–f)', 'Orientation','horizontal','Box','off');
    end
  end

  % Panel letters
  annot_letters();

  % Optional save
  save_tiff(fig, ['timeseries_BC_' doe_name('clim',clim_lbl{r})]);
end

%% ============================= FIGURE 2 =================================
% Time series: Rain + Biomass + WL/LOCP (SC/FC water & nitrogen)
for r = 1:2
  fig = figure(r+2); clf; set(fig,'Color','w','WindowState','maximized');

  % a) Rain
  subaxis(6,1,1,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025);
  plot(raindataup(R_rain(r),:),'-k','LineWidth',1.5); axis tight; xlim([0.5 128.5]);
  legend('annual rainfall (subplot a)','Location','northwest','Box','off'); legend('boxoff');
  title(clim_lbl{r}); ylabel('Rainfall (mm)'); set(gca,'FontSize',9);
  xticks(xTicks); xticklabels(''); box on;

  % b) Biomass
  subaxis(6,1,2,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025); hold on;
  for g = 1:4
    sim   = data_rain_graze_ss_m17{R_model(r), Graz(g), 1};
    plant = sim{1,1};
    [avgG, avgS] = get_avg_biomass(plant);
    plot(avgG,'-o','LineWidth',1.2,'MarkerSize',3,'Color',gColors(g,:));
    plot(avgS,'-x','LineWidth',1.2,'MarkerSize',5,'Color',gColors(g,:));
  end
  axis tight; xlim([0.5 128.5]); ylim([0 59]); yticks(15:15:45);
  ylabel('Biomass (g/m^2)'); set(gca,'FontSize',9); xticks(xTicks); xticklabels('');
  legend('grass (subplot b)','shrub (subplot b)','Orientation','horizontal','Box','off');

  % c–f) WL/LOCP time series (node-average to scalar)
  WL_SCw = avg_nodes(LOCP_SC_water);
  WL_FCw = avg_nodes(LOCP_FC_water);
  WL_SCn = avg_nodes(LOCP_SC_nitrogen);
  WL_FCn = avg_nodes(LOCP_FC_nitrogen);

  panel = {@() ylabel('WL SC water'), @() ylabel('WL FC water'), ...
           @() ylabel('WL SC nitrogen'), @() ylabel('WL FC nitrogen')};
  series = {@() squeeze(WL_SCw(r,:,:)), @() squeeze(WL_FCw(r,:,:)), ...
            @() squeeze(WL_SCn(r,:,:)), @() squeeze(WL_FCn(r,:,:))};
  ylims  = {[0 1.05e5], [0 23.5e6], [0 4.6e4], [0 7.9e4]};

  for p = 1:4
    subaxis(6,1,2+p,'ML',0.04,'MR',0.02,'MT',0.04,'MB',0.10,'sh',0.001,'sv',0.025); hold on;
    S = series{p}();                        % time x grazing(=4)
    for g = 1:4, plot(S(:,g), 'LineWidth',1.5,'Color',gColors(g,:)); end
    axis tight; xlim([0.5 128.5]); set(gca,'FontSize',9);
    if ~isempty(ylims{p}), ylim(ylims{p}); end
    panel{p}(); xticks(xTicks);
    if p < 4, xticklabels(''); else, xticklabels(xTickLbl); xlabel('Time (years)'); end
    if p == 4
      legend('1 g (c–f)','30% (c–f)','45% (c–f)','60% (c–f)', 'Orientation','horizontal','Box','off');
    end
  end

  annot_letters();
  save_tiff(fig, ['timeseries_WL_' doe_name('clim',clim_lbl{r})]);
end

%% ============================= FIGURE 5 =================================
% BC water maps (SC then FC) across climates x grazing x time
fig = figure(5); clf; set(fig,'Color','w','WindowState','maximized');
for r = 1:2
  for g = 1:4
    for t = 1:8
      % SC water
      A = squeeze(BC_SC_water(r,g,timeperiod(t),:)); A = reshape(A,100,100)'; % 100x100
      subaxis(8,16, 64*(r-1)+16*(g-1)+t, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(A); axis image off; caxis([0 1e6]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.50 0.02 0.40]; cb.Label.String='BC SC water';
      end

      % FC water
      B = squeeze(BC_FC_water(r,g,timeperiod(t),:)); B = reshape(B,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t+8, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(B); axis image off; caxis([0 1e6]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.05 0.02 0.40]; cb.Label.String='BC FC water';
      end
      if g==1 && r==1, title(time_lbl{t},'FontWeight','normal','FontSize',11); end
    end
  end
end
grid_labels('Dry Endmember','Wet Endmember','1 g','30 %','45 %','60 %');
save_tiff(fig, 'maps_BC_water');

%% ============================= FIGURE 6 =================================
% BC nitrogen maps (SC then FC)
fig = figure(6); clf; set(fig,'Color','w','WindowState','maximized');
for r = 1:2
  for g = 1:4
    for t = 1:8
      A = squeeze(BC_SC_nitrogen(r,g,timeperiod(t),:)); A = reshape(A,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(A); axis image off; caxis([0 1e6]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.50 0.02 0.40]; cb.Label.String='BC SC nitrogen';
      end

      B = squeeze(BC_FC_nitrogen(r,g,timeperiod(t),:)); B = reshape(B,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t+8, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(B); axis image off; caxis([0 1e6]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.05 0.02 0.40]; cb.Label.String='BC FC nitrogen';
      end
      if g==1 && r==1, title(time_lbl{t},'FontWeight','normal','FontSize',11); end
    end
  end
end
grid_labels('Dry Endmember','Wet Endmember','1 g','30 %','45 %','60 %');
save_tiff(fig, 'maps_BC_nitrogen');

%% ============================= FIGURE 7 =================================
% WL/LOCP water maps (SC then FC)
fig = figure(7); clf; set(fig,'Color','w','WindowState','maximized');
for r = 1:2
  for g = 1:4
    for t = 1:8
      A = squeeze(LOCP_SC_water(r,g,timeperiod(t),:)); A = reshape(A,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(A); axis image off; caxis([0 2e5]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.50 0.02 0.40]; cb.Label.String='WL SC water';
      end

      B = squeeze(LOCP_FC_water(r,g,timeperiod(t),:)); B = reshape(B,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t+8, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(B); axis image off; caxis([0 2e7]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.05 0.02 0.40]; cb.Label.String='WL FC water';
      end
      if g==1 && r==1, title(time_lbl{t},'FontWeight','normal','FontSize',11); end
    end
  end
end
grid_labels('Dry Endmember','Wet Endmember','1 g','30 %','45 %','60 %');
save_tiff(fig, 'maps_WL_water');

%% ============================= FIGURE 8 =================================
% WL/LOCP nitrogen maps (SC then FC)
fig = figure(8); clf; set(fig,'Color','w','WindowState','maximized');
for r = 1:2
  for g = 1:4
    for t = 1:8
      A = squeeze(LOCP_SC_nitrogen(r,g,timeperiod(t),:)); A = reshape(A,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(A); axis image off; caxis([0 5e4]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.50 0.02 0.40]; cb.Label.String='WL SC nitrogen';
      end

      B = squeeze(LOCP_FC_nitrogen(r,g,timeperiod(t),:)); B = reshape(B,100,100)';
      subaxis(8,16, 64*(r-1)+16*(g-1)+t+8, 'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);
      imagesc(B); axis image off; caxis([0 1e5]); colormap(jet);
      if t==1 && r==1 && g==1
        cb = colorbar; cb.Position=[0.936 0.05 0.02 0.40]; cb.Label.String='WL FC nitrogen';
      end
      if g==1 && r==1, title(time_lbl{t},'FontWeight','normal','FontSize',11); end
    end
  end
end
grid_labels('Dry Endmember','Wet Endmember','1 g','30 %','45 %','60 %');
save_tiff(fig, 'maps_WL_nitrogen');

%% ---------------------------- utilities --------------------------------
function annot_letters()
  annotation('textbox',[.048 .87  .1 .1],'String','a.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
  annotation('textbox',[.048 .72  .1 .1],'String','b.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
  annotation('textbox',[.048 .572 .1 .1],'String','c.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
  annotation('textbox',[.048 .42  .1 .1],'String','d.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
  annotation('textbox',[.048 .27  .1 .1],'String','e.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
  annotation('textbox',[.048 .112 .1 .1],'String','f.','FontSize',9,'FontWeight','Bold','EdgeColor','none');
end

function grid_labels(climA,climB,g1,g2,g3,g4)
  % Climate rows
  subaxis(1,1,1,'ML',0.02,'MR',0.975,'MT',0.075,'MB',0.482,'sh',0.01,'sv',0.01);
  axis off; ylabel(climA,'FontSize',11);
  subaxis(1,1,1,'ML',0.02,'MR',0.975,'MT',0.53,'MB',0.025,'sh',0.01,'sv',0.01);
  axis off; ylabel(climB,'FontSize',11);

  % Grazing labels (left half)
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.53,'MB',0.366,'sh',0.01,'sv',0.01); axis off; ylabel(g1);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.645,'MB',0.25 ,'sh',0.01,'sv',0.01); axis off; ylabel(g2);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.76 ,'MB',0.135,'sh',0.01,'sv',0.01); axis off; ylabel(g3);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.875,'MB',0.017,'sh',0.01,'sv',0.01); axis off; ylabel(g4);

  % Grazing labels (right half)
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.074,'MB',0.752,'sh',0.01,'sv',0.01); axis off; ylabel(g1);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.189,'MB',0.637,'sh',0.01,'sv',0.01); axis off; ylabel(g2);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.304,'MB',0.522,'sh',0.01,'sv',0.01); axis off; ylabel(g3);
  subaxis(1,1,1,'ML',0.045,'MR',0.952,'MT',0.419,'MB',0.407,'sh',0.01,'sv',0.01); axis off; ylabel(g4);

  % Column headers (top)
  subaxis(1,1,1,'ML',0.048,'MR',0.515,'MT',0.033,'MB',0.960,'sh',0.01,'sv',0.01);
  plot([1,1],[0,1],'k'); axis off; xlabel('Left panel');
  subaxis(1,1,1,'ML',0.495,'MR',0.07,'MT',0.033,'MB',0.960,'sh',0.01,'sv',0.01);
  plot([1,1],[0,1],'k'); axis off; xlabel('Right panel');
end
