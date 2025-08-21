% scripts/correlation_panels.m
% Correlation panels for rainfall, biomass, and network flows (GE/CD & BC/WL)
% -------------------------------------------------------------------------
% Outputs:
%   fig 1: GE/CD correlation matrices (Dry/Wet; grazing levels; lags)
%   fig 2: BC/WL correlation matrices (Dry/Wet; grazing levels; lags)
%   fig 3/4: Node-level instantaneous & lagged correlations (per r,g)
%
% Notes:
% - No 'cd' calls; set DATA_DIR/OUT_DIR below.
% - DoE-style run names via doe_name().
% - Fixed: stray parentheses (e.g., GE_SC_wat()), undefined 'w' in fig 3,
%          BD* vs BC_* / LOCP* mismatches, repeated colormap/code blocks.
% -------------------------------------------------------------------------

clearvars; close all; clc;

%% ----------------------------- Paths -----------------------------------
ROOT     = fileparts(mfilename('fullpath'));
DATA_DIR = fullfile(ROOT, '..', 'data');
OUT_DIR  = fullfile(ROOT, '..', 'figures');
if ~exist(OUT_DIR,'dir'), mkdir(OUT_DIR); end

%% --------------------------- Load data ---------------------------------
% Core sim
load(fullfile(DATA_DIR, 'data_rain_graze_ss_m17.mat'), 'data_rain_graze_ss_m17');

% Global exchange (GE) & cross-diffusion (CD) – time series (expect dims like [r,w,g,t])
load(fullfile(DATA_DIR,'GE_SC_water_1.mat'),      'GE_SC_water');
load(fullfile(DATA_DIR,'GE_FC_water_1.mat'),      'GE_FC_water');
load(fullfile(DATA_DIR,'GE_SC_nitrogen_1.mat'),   'GE_SC_nitrogen');
load(fullfile(DATA_DIR,'GE_FC_nitrogen_1.mat'),   'GE_FC_nitrogen');

load(fullfile(DATA_DIR,'CD_SC_water.mat'),        'CD_SC_water');
load(fullfile(DATA_DIR,'CD_FC_water.mat'),        'CD_FC_water');
load(fullfile(DATA_DIR,'CD_SC_nitrogen.mat'),     'CD_SC_nitrogen');
load(fullfile(DATA_DIR,'CD_FC_nitrogen.mat'),     'CD_FC_nitrogen');

% Boundary coupling (BC) & Local Pass (WL / LOCP) – nodewise (r,g,t,10000)
load(fullfile(DATA_DIR,'BC_SC_water.mat'),        'BC_SC_water');
load(fullfile(DATA_DIR,'BC_FC_water.mat'),        'BC_FC_water');
load(fullfile(DATA_DIR,'BC_SC_nitrogen.mat'),     'BC_SC_nitrogen');
load(fullfile(DATA_DIR,'BC_FC_nitrogen.mat'),     'BC_FC_nitrogen');

load(fullfile(DATA_DIR,'LOCP_SC_water.mat'),      'LOCP_SC_water');   % WL SC water
load(fullfile(DATA_DIR,'LOCP_FC_water.mat'),      'LOCP_FC_water');   % WL FC water
load(fullfile(DATA_DIR,'LOCP_SC_nitrogen.mat'),   'LOCP_SC_nitrogen');% WL SC nitrogen
load(fullfile(DATA_DIR,'LOCP_FC_nitrogen.mat'),   'LOCP_FC_nitrogen');% WL FC nitrogen

% Rainfall
load(fullfile(DATA_DIR,'scaled_series.mat'), 'scaled_series');
load(fullfile(DATA_DIR,'raindata.mat'),      'raindata');

% Match your original construction
raindataup = [raindata(2,:); scaled_series; raindata(3,:)];

%% ---------------------------- Factors ----------------------------------
% Climate, wind, grazing
R_CLIM_IDX  = [1 4];                               % Dry, Wet (from your R=[1 4])
GRAZ_IDX    = [1 2 5 8];                           % "1g","30%","45%","60%"
WIND_USE    = 1;                                   % you used w=1 (downslope) throughout
GRAZ_LBL    = {'1 g','30%','45%','60%'};
CLIM_LBL    = {'Dry Endmember','Wet Endmember'};
CLIM_KEY    = {'dry','wet'};

% Lags in time steps and their label in "years"
LAG_STEPS   = [1 2 4 8 16];                        % index shift
LAG_YEARS   = [0 2 4 8 16];                        % label as years (your original)

% Time axis labels for 128 samples (47:174 years subset)
xTicks      = [1 6:20:126];
xTickLbl    = {'1895','1900','1920','1940','1960','1980','2000','2020'};

% Colormap (blue-white-red, 121 steps)
WS = ws_colormap();

%% ---------------------- Helper: biomass means --------------------------
get_biomass_ts = @(plant) deal( ...
  squeeze(mean(mean( plant(47:end,11:110,11:110,1),3,'omitnan'),2,'omitnan')) , ...
  squeeze(mean(mean( plant(47:end,11:110,11:110,2),3,'omitnan'),2,'omitnan')) );

%% ============================ FIGURE 1 =================================
% GE/CD correlations vs lag (Dry/Wet x Grazing)
figure(1); clf; set(gcf,'Color','w');

for r = 1:2
  climIdx = R_CLIM_IDX(r);

  for g = 1:4
    % --- biomass time series (avg across inner 100x100) ---
    dat          = data_rain_graze_ss_m17{climIdx, GRAZ_IDX(g), WIND_USE};
    plant        = dat{1,1};
    [avgGrass, avgShrub] = get_biomass_ts(plant);

    % --- scalar timeseries (GE/CD) ---
    GE_SC_wat = squeeze(GE_SC_water(r, WIND_USE, g, :));
    GE_FC_wat = squeeze(GE_FC_water(r, WIND_USE, g, :));
    GE_SC_nit = squeeze(GE_SC_nitrogen(r, WIND_USE, g, :));
    GE_FC_nit = squeeze(GE_FC_nitrogen(r, WIND_USE, g, :));

    CD_SC_wat = squeeze(CD_SC_water(r, WIND_USE, g, :));
    CD_FC_wat = squeeze(CD_FC_water(r, WIND_USE, g, :));
    CD_SC_nit = squeeze(CD_SC_nitrogen(r, WIND_USE, g, :));
    CD_FC_nit = squeeze(CD_FC_nitrogen(r, WIND_USE, g, :));

    rain       = raindataup(climIdx, :)';

    % 11 variables, column-wise
    M = [ rain, avgGrass, avgShrub, ...
          GE_SC_wat, GE_FC_wat, GE_SC_nit, GE_FC_nit, ...
          CD_SC_wat, CD_FC_wat, CD_SC_nit, CD_FC_nit ]';

    for t = 1:numel(LAG_STEPS)
      T = LAG_STEPS(t);
      C = corr_at_lag(M, T);         % 11x11

      subaxis(4,10, 10*g + 5*r + t - 15, 'ML',0.08,'MR',0.004,'MT',0.095,'MB',0.11,'sh',0.004,'sv',0.004);
      imagesc(C); axis image; caxis([-1 1]); colormap(WS); set(gca,'FontSize',8);
      xticks(1:11); yticks(1:11); xticklabels(''); yticklabels(''); xtickangle(90);

      if g==1, title(sprintf('Delay = %d years', LAG_YEARS(t)), 'FontWeight','normal'); end
      if r==1 && t==1
        yticklabels({'Rainfall','Grass','Shrub','GE SC water','GE FC water','GE SC nitrogen','GE FC nitrogen','CD SC water','CD FC water','CD SC nitrogen','CD FC nitrogen'});
        ylabel(['Grazing = ', GRAZ_LBL{g}], 'FontSize',10);
      end
      if g==4 && r==1 && t==1
        xticklabels({'Rainfall','Grass','Shrub','GE SC water','GE FC water','GE SC nitrogen','GE FC nitrogen','CD SC water','CD FC water','CD SC nitrogen','CD FC nitrogen'});
        cb = colorbar('southoutside'); cb.Position=[0.2 0.065 0.6 0.04];
        cb.Label.String='Correlation Coefficient';
      end
    end
  end
end

% Top labels: Dry/Wet
top_label(0.0794, 0.464, 'Dry Endmember');
top_label(0.5385, 0.0025, 'Wet Endmember');

save_tiff(gcf, OUT_DIR, ['corr_GE_CD_', doe_name('scope','panel','clim','dry_wet','wind','downslope')]);

%% ============================ FIGURE 2 =================================
% BC/WL (LOCP) correlations vs lag (Dry/Wet x Grazing)
figure(2); clf; set(gcf,'Color','w');

for r = 1:2
  climIdx = R_CLIM_IDX(r);

  for g = 1:4
    % Biomass (avg 100x100)
    dat          = data_rain_graze_ss_m17{climIdx, GRAZ_IDX(g), WIND_USE};
    plant        = dat{1,1};
    [avgGrass, avgShrub] = get_biomass_ts(plant);

    % BC/WL: average over nodes to get scalar series
    BC_SC_wat = squeeze(mean(BC_SC_water(r,g,:,:), 4));
    BC_FC_wat = squeeze(mean(BC_FC_water(r,g,:,:), 4));
    BC_SC_nit = squeeze(mean(BC_SC_nitrogen(r,g,:,:), 4));
    BC_FC_nit = squeeze(mean(BC_FC_nitrogen(r,g,:,:), 4));

    WL_SC_wat = squeeze(mean(LOCP_SC_water(r,g,:,:), 4));
    WL_FC_wat = squeeze(mean(LOCP_FC_water(r,g,:,:), 4));
    WL_SC_nit = squeeze(mean(LOCP_SC_nitrogen(r,g,:,:), 4));
    WL_FC_nit = squeeze(mean(LOCP_FC_nitrogen(r,g,:,:), 4));

    rain = raindataup(climIdx, :)';

    % 11 variables
    M = [ rain, avgGrass, avgShrub, ...
          BC_SC_wat, BC_FC_wat, BC_SC_nit, BC_FC_nit, ...
          WL_SC_wat, WL_FC_wat, WL_SC_nit, WL_FC_nit ]';

    for t = 1:numel(LAG_STEPS)
      T = LAG_STEPS(t);
      C = corr_at_lag(M, T);

      subaxis(4,10, 10*g + 5*r + t - 15, 'ML',0.08,'MR',0.004,'MT',0.095,'MB',0.11,'sh',0.004,'sv',0.004);
      imagesc(C); axis image; caxis([-1 1]); colormap(WS); set(gca,'FontSize',8);
      xticks(1:11); yticks(1:11); xticklabels(''); yticklabels(''); xtickangle(90);

      if g==1, title(sprintf('Delay = %d years', LAG_YEARS(t)), 'FontWeight','normal'); end
      if r==1 && t==1
        yticklabels({'Rainfall','Grass','Shrub','BC SC water','BC FC water','BC SC nitrogen','BC FC nitrogen','WL SC water','WL FC water','WL SC nitrogen','WL FC nitrogen'});
        ylabel(['Grazing = ', GRAZ_LBL{g}], 'FontSize',10);
      end
      if g==4 && r==1 && t==1
        xticklabels({'Rainfall','Grass','Shrub','BC SC water','BC FC water','BC SC nitrogen','BC FC nitrogen','WL SC water','WL FC water','WL SC nitrogen','WL FC nitrogen'});
        cb = colorbar('southoutside'); cb.Position=[0.2 0.065 0.6 0.04];
        cb.Label.String='Correlation Coefficient';
      end
    end
  end
end

top_label(0.0794, 0.464, 'Dry Endmember');
top_label(0.5385, 0.0025, 'Wet Endmember');

save_tiff(gcf, OUT_DIR, ['corr_BC_WL_', doe_name('scope','panel','clim','dry_wet','wind','downslope')]);

%% ============================ FIGURE 3/4 ===============================
% Node-level instantaneous correlations (45 pairs) and lagged (grass±/shrub vs others)
% One figure per (r,g): fig 3 = instantaneous; fig 4 = lagged
for r = 1:2
  climIdx = R_CLIM_IDX(r);
  for g = 1:4
    % ---- Build nodewise matrices (time x nodes) for 10 variables ----
    % biomass (time x nodes) from plant
    dat    = data_rain_graze_ss_m17{climIdx, GRAZ_IDX(g), WIND_USE};
    plant  = dat{1,1};
    Gcube  = squeeze(plant(47:end,11:110,11:110,1));   % 128 x 100 x 100
    Scube  = squeeze(plant(47:end,11:110,11:110,2));
    grass_nodes = reshape(permute(Gcube,[1 3 2]), 128, []);   % 128 x 10000
    shrub_nodes = reshape(permute(Scube,[1 3 2]), 128, []);

    % BC & WL are assumed (r,g,time,10000)
    bcSCw = squeeze(BC_SC_water(r,g,:,:));    % 128 x 10000
    bcFCw = squeeze(BC_FC_water(r,g,:,:));
    bcSCn = squeeze(BC_SC_nitrogen(r,g,:,:));
    bcFCn = squeeze(BC_FC_nitrogen(r,g,:,:));

    wlSCw = squeeze(LOCP_SC_water(r,g,:,:));
    wlFCw = squeeze(LOCP_FC_water(r,g,:,:));
    wlSCn = squeeze(LOCP_SC_nitrogen(r,g,:,:));
    wlFCn = squeeze(LOCP_FC_nitrogen(r,g,:,:));

    % stack: 10 variables (rows) x (time*nodes) columns when vectorized per-time
    V = {grass_nodes, shrub_nodes, bcSCw, bcFCw, bcSCn, bcFCn, wlSCw, wlFCw, wlSCn, wlFCn};

    % -------- Instantaneous, per-time (lower triangle, 45 pairs) --------
    instCorr = zeros(45, 128);
    for t = 1:128
      % 10 column vectors of length 10000 at time t
      X = cellfun(@(A) A(t,:).', V, 'UniformOutput', false);
      M = cell2mat(X);                    % 10000 x 10
      C = corr(M);                        % 10 x 10
      v = tril(C,-1); v = v(:); v(v==0) = [];   % 45 x 1
      instCorr(:,t) = v;
    end

    f3 = figure(3 + 2*(g-1) + (r-1)); clf; set(f3,'Color','w');
    subaxis(1,1,1,'ML',0.12,'MR',0.004,'MT',0.05,'MB',0.15,'sh',0.004,'sv',0.004);
    imagesc(instCorr); caxis([-1 1]); colormap(WS);
    set(gca,'FontSize',8); colorbar('southoutside','Position',[0.26 0.06 0.6 0.04], ...
           'Label','Correlation Coefficient');
    title(sprintf('Node-level Correlation | %s | Grazing = %s', CLIM_LBL{r}, GRAZ_LBL{g}), ...
          'FontWeight','normal');
    xticks(xTicks); xticklabels(xTickLbl); xlabel('Time (years)');
    yticks(1:45);
    yticklabels({ ...
      'grass & shrub','grass & BC SC water','shrub & BC SC water','grass & BC FC water','shrub & BC FC water','BC SC water & BC FC water', ...
      'grass & BC SC nitrogen','shrub & BC SC nitrogen','BC SC water & BC SC nitrogen','BC FC water & BC SC nitrogen', ...
      'grass & BC FC nitrogen','shrub & BC FC nitrogen','BC SC water & BC FC nitrogen','BC FC water & BC FC nitrogen','BC SC nitrogen & BC FC nitrogen', ...
      'grass & WL SC water','shrub & WL SC water','BC SC water & WL SC water','BC FC water & WL SC water','BC SC nitrogen & WL SC water','BC FC nitrogen & WL SC water', ...
      'grass & WL FC water','shrub & WL FC water','BC SC water & WL FC water','BC FC water & WL FC water','BC SC nitrogen & WL FC water','BC FC nitrogen & WL FC water','WL SC water & WL FC water', ...
      'grass & WL SC nitrogen','shrub & WL SC nitrogen','BC SC water & WL SC nitrogen','BC FC water & WL SC nitrogen','BC SC nitrogen & WL SC nitrogen','BC FC nitrogen & WL SC nitrogen','WL SC water & WL SC nitrogen','WL FC water & WL SC nitrogen', ...
      'grass & WL FC nitrogen','shrub & WL FC nitrogen','BC SC water & WL FC nitrogen','BC FC water & WL FC nitrogen','BC SC nitrogen & WL FC nitrogen','BC FC nitrogen & WL FC nitrogen','WL SC water & WL FC nitrogen','WL FC water & WL FC nitrogen','WL SC nitrogen & WL FC nitrogen' ...
    });
    ylabel('Pearson r');
    save_tiff(f3, OUT_DIR, ['nodecorr_inst_', doe_name('clim',CLIM_KEY{r},'graz',strrep(GRAZ_LBL{g},' ','') )]);

    % -------- Lagged node-level corr (grass/shrub vs others), d=[4,8,16] --------
    DEL = [4 8 16];
    pairs = { ... % (target, reference)
      2,1;  3,1;  4,1;  5,1;  6,1;  7,1;  8,1;  9,1;  10,1; ...  grass with others (shrub..WL FC N)
      1,2;  3,2;  4,2;  5,2;  6,2;  7,2;  8,2;  9,2};           % shrub with others (grass..WL FC W)
    np = size(pairs,1);

    f4 = figure(4 + 2*(g-1) + (r-1)); clf; set(f4,'Color','w');
    for k = 1:numel(DEL)
      d = DEL(k);
      mat = zeros(np, 128-d);
      for t = 1:(128-d)
        xcols = cellfun(@(A) A(t,:).', V, 'UniformOutput', false);      % time t
        ycols = cellfun(@(A) A(t+d,:).', V, 'UniformOutput', false);    % time t+d
        X = cell2mat(xcols);  % 10000 x 10
        Y = cell2mat(ycols);  % 10000 x 10
        rvec = zeros(np,1);
        for p = 1:np
          a = pairs{p,1}; b = pairs{p,2};
          rvec(p) = corr(X(:,a), Y(:,b));   % var_a at t  vs var_b at t+d
        end
        mat(:,t) = rvec;
      end
      subaxis(3,1,k,'ML',0.14,'MR',0.004,'MT',0.03,'MB',0.15,'sh',0.004,'sv',0.004);
      imagesc(mat); caxis([-0.8 0.8]); colormap(WS); set(gca,'FontSize',8);
      if k==1
        title(sprintf('Node-level Lagged r | %s | Grazing = %s', CLIM_LBL{r}, GRAZ_LBL{g}), ...
              'FontWeight','normal');
      end
      xticks(xTicks(xTicks<=size(mat,2))); xticklabels([]); ylim([0.5 np+0.5]);
      if k==numel(DEL)
        xticks(xTicks(xTicks<=size(mat,2))); xticklabels(xTickLbl); xlabel('Time (years)');
      end
      yticklabels(lag_labels(d)); yticks(1:np);
      colorbar('southoutside','Position',[0.26 0.06 0.6 0.04], 'Label','Correlation Coefficient', ...
               'Visible', iff(k==1,'on','off'));
    end
    save_tiff(f4, OUT_DIR, ['nodecorr_lag_', doe_name('clim',CLIM_KEY{r},'graz',strrep(GRAZ_LBL{g},' ',''))]);
  end
end

%% ------------------------------ Helpers --------------------------------
function C = corr_at_lag(M, T)
% M: (nVar x Tlen) column-major; T: shift in samples
  n = size(M,1);
  C = zeros(n,n);
  a = 1:(size(M,2)-T);
  b = (1+T):size(M,2);
  for i=1:n
    xi = M(i,a)';
    for j=1:n
      yj = M(j,b)';
      C(i,j) = corr(xi,yj);
    end
  end
end

function name = doe_name(varargin)
% doe_name('clim','dry','wind','downslope','graz','30pct','scope','panel',...)
  if mod(numel(varargin),2)~=0
    error('doe_name expects name/value pairs');
  end
  parts = strings(1,numel(varargin)/2);
  k = 1;
  for i=1:2:numel(varargin)
    key = lower(string(varargin{i}));
    val = lower(regexprep(string(varargin{i+1}),'\s+',''));
    parts(k) = key + "-" + val; k=k+1;
  end
  name = strjoin(parts, "_");
end

function C = ws_colormap()
  base = [ ...
    0.0314 0.1882 0.4196
    0.0314 0.3176 0.6118
    0.1294 0.4431 0.7098
    0.2588 0.5725 0.7765
    0.4196 0.6824 0.8392
    0.6196 0.7922 0.8824
    0.7765 0.8588 0.9373
    0.8706 0.9216 0.9686
    1 1 1
    0.9961 0.8784 0.8235
    0.9882 0.7333 0.6314
    0.9882 0.5725 0.4471
    0.9843 0.4157 0.2902
    0.9373 0.2314 0.1725
    0.7961 0.0941 0.1137
    0.6471 0.0588 0.0824
    0.4039 0 0.0510];
  C = interp1(linspace(0,1,size(base,1)), base, linspace(0,1,121), 'linear');
end

function top_label(ML, MR, txt)
  subaxis(1,1,1,'ML',ML,'MR',MR,'MT',0.058,'MB',0.920,'sh',0.01,'sv',0.01);
  plot([1,1],[0,1],'k'); axis off; set(gca,'XAxisLocation','top');
  xlabel(txt); set(gca,'FontSize',10,'FontWeight','normal');
end

function out = iff(cond, a, b)
  if ischar(a), a = string(a); end
  if ischar(b), b = string(b); end
  if cond, out = a; else, out = b; end
end

function save_tiff(fig, outDir, base)
  print(fig, fullfile(outDir, [base '.tiff']), '-dtiff', '-r300');
end

function L = lag_labels(d)
  L = { ...
    sprintf('shrub & grass at d = %d',d), ...
    sprintf('BC SC water & grass at d = %d',d), ...
    sprintf('BC FC water & grass at d = %d',d), ...
    sprintf('BC SC nitrogen & grass at d = %d',d), ...
    sprintf('BC FC nitrogen & grass at d = %d',d), ...
    sprintf('WL SC water & grass at d = %d',d), ...
    sprintf('WL FC water & grass at d = %d',d), ...
    sprintf('WL SC nitrogen & grass at d = %d',d), ...
    sprintf('WL FC nitrogen & grass at d = %d',d), ...
    sprintf('grass & shrub at d = %d',d), ...
    sprintf('BC SC water & shrub at d = %d',d), ...
    sprintf('BC FC water & shrub at d = %d',d), ...
    sprintf('BC SC nitrogen & shrub at d = %d',d), ...
    sprintf('BC FC nitrogen & shrub at d = %d',d), ...
    sprintf('WL SC water & shrub at d = %d',d), ...
    sprintf('WL FC water & shrub at d = %d',d), ...
    sprintf('WL SC nitrogen & shrub at d = %d',d), ...
    sprintf('WL FC nitrogen & shrub at d = %d',d) };
end
