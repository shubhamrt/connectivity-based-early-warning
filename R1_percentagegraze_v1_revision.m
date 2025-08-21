% scripts/make_figures.m
% Clean, GitHub-ready plotting & naming for rainfall–grazing experiments
% ----------------------------------------------------------------------
% Usage:
%   run('scripts/make_figures.m')
%
% Requirements: subaxis (or switch to tiledlayout), data .mat files below.
% ----------------------------------------------------------------------

clearvars; close all; clc;

%% ----------------------------- Config ---------------------------------
% Folders (use relative paths instead of cd)
ROOT      = fileparts(mfilename('fullpath'));
DATA_DIR  = fullfile(ROOT, '..', 'data');        % <--- put .mat data here
OUT_DIR   = fullfile(ROOT, '..', 'figures');     % <--- output figures here
if ~exist(OUT_DIR, 'dir'); mkdir(OUT_DIR); end

% Data files
RAIN_SERIES_FILE = fullfile(DATA_DIR, 'scaled_series.mat');
RAINDATA_FILE    = fullfile(DATA_DIR, 'raindata.mat');
SIM_FILE         = fullfile(DATA_DIR, 'data_rain_graze_ss_m17.mat');

% Experiment factors
GRAZING_IDX = [1 2 5 8];                    % indices into data cell
CLIM_IDX    = [1 3 7 9];                    % climates to plot
WIND_NAMES  = {'downslope','upslope'};      % w=1,2
GRAZ_NAMES  = {'1g','30pct','45pct','60pct'};

% Climate labels (short + long)
CLIM_SHORT  = {'Dry','ModDry','ModWet','Wet'};
CLIM_LONG   = { ...
  'Dry Endmember (MAR=132.1 mm & CoV=38.1)', ...
  'Modified Dry Endmember (MAR=132.1 mm & CoV=22.8)', ...
  'Modified Wet Endmember (MAR=286.2 mm & CoV=38.1)', ...
  'Wet Endmember (MAR=286.2 mm & CoV=22.8)'};

% Time axes / labels
time_idx   = [46 51 71 91 111 131 151 171] + 1;
time_lbl   = {'1895','1900','1920','1940','1960','1980','2000','2020'};

% Colors
AAA = jet(4);                 % grazing colors
WS  = util_ws_colormap();     % blue-white-red colormap
set(0, 'defaultLegendBox','off');

%% ------------------------------ Load ----------------------------------
load(RAIN_SERIES_FILE, 'scaled_series');
load(RAINDATA_FILE, 'raindata');
load(SIM_FILE, 'data_rain_graze_ss_m17');

% Prepend/append to match your original “raindataup” construction
raindataup = [raindata(2,:); scaled_series; raindata(3,:)];

%% ------------------------ Figure A/B/C set -----------------------------
% Rainfall (top) + mean grass/shrub vs time (two rows) per climate
for rIdx = 1:numel(CLIM_IDX)
  r = CLIM_IDX(rIdx);

  fig = figure('Color','w'); clf; fig.WindowState = 'maximized';

  % (a) Rainfall panel ----------------------------------------------------
  subaxis(1,1,1,'ML',0.04,'MR',0.02,'MT',0.02,'MB',0.775,'sh',0.01,'sv',0.02);
  plot(raindataup(r,:),'-','LineWidth',2,'Color','k'); hold on
  ylim([0 700]); xlim([0.5 128.5]);
  ylabel('Annual Rainfall (mm)');
  xticks([1 6:20:126]); xticklabels({''}); grid on; box on
  legend(CLIM_LONG{rIdx}, 'Location','northeast');

  % (b,c) Mean grass/shrub across grazing & wind -------------------------
  for w = 1:2
    for g = 1:4
      dat   = data_rain_graze_ss_m17{r, GRAZING_IDX(g), w};
      plant = dat{1,1};   % [time, 120,120, species]

      grass = squeeze(plant(47:end, 11:110, 11:110, 1));
      shrub = squeeze(plant(47:end, 11:110, 11:110, 2));
      avgG  = squeeze(mean(mean(grass,3,'omitnan'),2,'omitnan'))';
      avgS  = squeeze(mean(mean(shrub,3,'omitnan'),2,'omitnan'))';

      % row 1 of bottom: grass
      subaxis(2,1,1,'ML',0.04,'MR',0.02,'MT',0.25,'MB',0.08,'sh',0.01,'sv',0.02);
      ls = iff(w==1, '-', '--'); 
      plot(avgG, ls, 'LineWidth',1.5, 'Color', AAA(g,:)); hold on
      ylabel('Mean Grass (g m^{-2})'); ylim([0 65]); xlim([0.5 128.5]);
      xticks([1 6:20:126]); xticklabels({''}); grid on

      % row 2 of bottom: shrub
      subaxis(2,1,2,'ML',0.04,'MR',0.02,'MT',0.25,'MB',0.08,'sh',0.01,'sv',0.02);
      plot(avgS, ls, 'LineWidth',1.5, 'Color', AAA(g,:)); hold on
      ylabel('Mean Shrub (g m^{-2})'); ylim([0 65]); xlim([0.5 128.5]);
      xticks([1 6:20:126]); xticklabels(time_lbl); grid on
    end
  end

  % Legends + small text once
  subaxis(2,1,1); legend('1 g m^{-2} yr^{-1}','30%','45%','60%','Location','northwest');
  util_small_text(0.09, 0.295, 'solid = downslope, dotted = upslope');
  util_small_text(0.09, 0.245, 'Grazing Intensity');

  % Save with a DoE-style name
  runName = util_doe_name('clim', CLIM_SHORT{rIdx});
  fbase   = sprintf('timeseries_%s', runName);
  util_save_tiff(fig, OUT_DIR, fbase);
end

%% ---------------------- Biomass maps (G±S) -----------------------------
% Panel grid: (r,w,g,time). Uses sign(G-S)*(G+S) like your original.
for group = 1:2
  % group 1: Dry/Wet; group 2: ModDry/ModWet
  if group==1
    Rplot = [1 4]; rowLabel = {'Dry Endmember','Wet Endmember'};
  else
    Rplot = [2 3]; rowLabel = {'Modified Dry','Modified Wet'};
  end

  fig = figure('Color','w'); clf; fig.WindowState = 'maximized';

  for rRow = 1:2
    r = CLIM_IDX(Rplot(rRow));

    for w = 1:2
      for g = 1:4
        for t = 1:8
          dat   = data_rain_graze_ss_m17{r, GRAZING_IDX(g), w};
          plant = dat{1,1};
          grass = squeeze(plant(:,11:110,11:110,1));
          shrub = squeeze(plant(:,11:110,11:110,2));

          subaxis(8,16, 64*rRow-64 + 16*g-16 + 8*w-8 + t, ...
                  'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);

          A = squeeze(grass(time_idx(t),:,:));
          S = squeeze(shrub(time_idx(t),:,:));
          imagesc( sign(A-S) .* (A+S) ); axis image off; caxis([-225 225]);
          colormap(WS);

          if g==1 && rRow==1, title(time_lbl{t}); end
          if t==1 && w==1 && rRow==1 && g==1
            cb = colorbar; cb.Position=[0.936 0.18 0.02 0.6];
            cb.Label.String = 'Shrub ◀  Total Biomass (g m^{-2}) ▶ Grass';
          end
        end
      end
    end
  end

  % Row/column labels
  util_side_label(0.02,0.975,0.075,0.482, rowLabel{1});
  util_side_label(0.02,0.975,0.53,0.025,  rowLabel{2});
  util_row_label(0.045,0.952,0.53,0.366,'1 g');
  util_row_label(0.045,0.952,0.645,0.25,'30%');
  util_row_label(0.045,0.952,0.76,0.135,'45%');
  util_row_label(0.045,0.952,0.875,0.017,'60%');
  util_top_label(0.048,0.515,'Wind Downslope');
  util_top_label(0.495,0.07,'Wind Upslope');

  runName = util_doe_name('panel', iff(group==1,'DryWet','ModDryModWet'));
  util_save_tiff(fig, OUT_DIR, ['biomass_grid_' runName]);
end

%% ---------------------- Grass-only & Shrub-only grids ------------------
% Same layout; separate colormap ranges for grass/shrub.
for species = ["grass","shrub"]
  fig = figure('Color','w'); clf; fig.WindowState = 'maximized';

  for rRow = 1:2
    r = CLIM_IDX(rRow==1*[1] + rRow==2*[4]); % dry/wet top/bottom
    for w = 1:2
      for g = 1:4
        for t = 1:8
          dat   = data_rain_graze_ss_m17{r, GRAZING_IDX(g), w};
          plant = dat{1,1};
          G = squeeze(plant(:,11:110,11:110,1));
          S = squeeze(plant(:,11:110,11:110,2));

          subaxis(8,16, 64*rRow-64 + 16*g-16 + 8*w-8 + t, ...
                  'ML',0.05,'MR',0.07,'MT',0.07,'MB',0.02,'sh',0.005,'sv',0.005);

          if species=="grass"
            imagesc(squeeze(G(time_idx(t),:,:))); colormap(WS(61:121,:)); caxis([0 200]);
            if g==1 && rRow==1, title(time_lbl{t}); end
            if t==1 && w==1 && rRow==1 && g==1
              cb = colorbar; cb.Position=[0.936 0.18 0.02 0.6];
              cb.Label.String = 'Grass Biomass (g m^{-2})';
            end
          else
            imagesc(squeeze(S(time_idx(t),:,:))); colormap(flipud(WS(1:61,:))); caxis([0 200]);
            if g==1 && rRow==1, title(time_lbl{t}); end
            if t==1 && w==1 && rRow==1 && g==1
              cb = colorbar; cb.Position=[0.936 0.18 0.02 0.6];
              cb.Label.String = 'Shrub Biomass (g m^{-2})';
            end
          end

          axis image off;
        end
      end
    end
  end

  % Labels
  util_side_label(0.02,0.975,0.075,0.482,'Dry Endmember');
  util_side_label(0.02,0.975,0.53,0.025,'Wet Endmember');
  util_row_label(0.045,0.952,0.53,0.366,'1 g'); 
  util_row_label(0.045,0.952,0.645,0.25,'30%');
  util_row_label(0.045,0.952,0.76,0.135,'45%');
  util_row_label(0.045,0.952,0.875,0.017,'60%');
  util_top_label(0.048,0.515,'Wind Downslope');
  util_top_label(0.495,0.07, 'Wind Upslope');

  runName = util_doe_name('what', species);
  util_save_tiff(fig, OUT_DIR, ['biomass_', char(species), '_grid_', runName]);
end

%% ------------------------ Local helper functions -----------------------
function out = iff(cond, a, b)
  if cond, out = a; else, out = b; end
end

function util_save_tiff(fig, outDir, base)
  fn = fullfile(outDir, [base, '.tiff']);
  print(fig, fn, '-dtiff', '-r300');
  fprintf('Saved: %s\n', fn);
end

function name = util_doe_name(varargin)
% util_doe_name('clim','Dry','wind','downslope','graz','45pct',...)
% Builds compact, searchable run/file names for DoE factors.
  p = inputParser;
  addParameter(p,'clim',''); addParameter(p,'wind','');
  addParameter(p,'graz',''); addParameter(p,'panel',''); addParameter(p,'what','');
  parse(p,varargin{:});
  bits = {};
  if ~isempty(p.Results.clim),  bits{end+1} = lower(p.Results.clim);  end
  if ~isempty(p.Results.wind),  bits{end+1} = lower(p.Results.wind);  end
  if ~isempty(p.Results.graz),  bits{end+1} = lower(p.Results.graz);  end
  if ~isempty(p.Results.panel), bits{end+1} = lower(p.Results.panel); end
  if ~isempty(p.Results.what),  bits{end+1} = lower(p.Results.what);  end
  name = strjoin(bits, '_');
  name = regexprep(name, '\s+', '');
end

function util_small_text(x,y,str)
  annotation('textbox',[x y .1 .1],'String',str,'FontSize',11, ...
             'FontWeight','normal','FitBoxToText','on','Color','k','EdgeColor','none');
end

function util_side_label(ml,mr,mt,mb,txt)
  subaxis(1,1,1,'ML',ml,'MR',mr,'MT',mt,'MB',mb,'sh',0.01,'sv',0.01);
  plot([0,1],[1,1],'k'); ylim([0 1]); axis off
  ylabel(txt); set(gca,'FontSize',11,'FontWeight','normal');
end

function util_row_label(ml,mr,mt,mb,txt)
  subaxis(1,1,1,'ML',ml,'MR',mr,'MT',mt,'MB',mb,'sh',0.01,'sv',0.01);
  plot([0,1],[1,1],'k'); ylim([0 1]); axis off
  ylabel(txt); set(gca,'FontSize',11,'FontWeight','normal');
end

function util_top_label(ml,mr,txt)
  subaxis(1,1,1,'ML',ml,'MR',mr,'MT',0.033,'MB',0.960,'sh',0.01,'sv',0.01);
  plot([1,1],[0,1],'k'); axis off; set(gca,'XAxisLocation','top');
  xlabel(txt); set(gca,'FontSize',11,'FontWeight','normal');
end

function C = util_ws_colormap()
% Blue → white → red colormap (interpolated to 121 colors)
  wscolors = [ ...
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
  x0 = linspace(0,1,size(wscolors,1));
  C  = interp1(x0, wscolors, linspace(0,1,121), 'linear');
end
