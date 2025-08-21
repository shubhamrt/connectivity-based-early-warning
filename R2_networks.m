function R1_networks(CFG)
% R1_NETWORKS  Build structural/functional networks (water & nitrogen)
% from ecogeomorphic model outputs and save them to disk.
%
% INPUT
%   CFG (struct) with fields:
%     - data_file : full path to 'data_rain_graze_ss_m17.mat'
%     - save_dir  : folder for large outputs (ignored by Git)
%     - save_tag  : optional string tag for saved filenames (default '1')
%
% OUTPUT (saved as .mat files in CFG.save_dir)
%   SC_water_net_<tag>.mat,   FC_water_net_<tag>.mat
%   SC_nitrogen_net_<tag>.mat,FC_nitrogen_net_<tag>.mat
%   GE_SC_water_<tag>.mat,    GE_FC_water_<tag>.mat
%   GE_SC_nitrogen_<tag>.mat, GE_FC_nitrogen_<tag>.mat
%
% NOTES
%  - This script is path-agnostic. Do NOT edit with hard-coded 'cd'.
%  - Large files are saved to CFG.save_dir. Keep that directory in .gitignore.

    if nargin==0 || ~isstruct(CFG)
        % Try to load repo config/config.m if CFG not passed in
        here = fileparts(mfilename('fullpath'));
        repo = fileparts(here);
        cfgFile = fullfile(repo,'config','config.m');
        if exist(cfgFile,'file'), run(cfgFile); else
            error('R1_networks:CFG','Provide CFG or create config/config.m (see README).');
        end
    end
    if ~isfield(CFG,'save_tag'), CFG.save_tag = '1'; end
    if ~exist(CFG.data_file,'file')
        error('R1_networks:data','Cannot find data file: %s',CFG.data_file);
    end
    if ~exist(CFG.save_dir,'dir'), mkdir(CFG.save_dir); end

    % ---- constants / dimensions ----
    fieldsize = 120;
    boundry   = 10;
    nYears    = 128;      % time steps after warm-up (47: end in original)
    Gidx      = [1 2 5 8];% grazing scenarios in your original data
    Ridx      = [1 4];    % rainfall regimes to use
    nR = numel(Ridx); nW = 2; nG = numel(Gidx); nT = nYears;

    grassThr  = 31.9;     % thresholds used in original script
    shrubThr  = 22.2;

    % ---- precompute boundary bookkeeping (static) ----
    [sidebound1, sidebound2, removeboundary] = boundary_indices(fieldsize,boundry);

    % Load model bundle
    S = load(CFG.data_file);                 % expects 'data_rain_graze_ss_m17'
    if ~isfield(S,'data_rain_graze_ss_m17')
        error('R1_networks:data','Expected variable ''data_rain_graze_ss_m17'' in %s',CFG.data_file);
    end
    data_rain_graze_ss_m17 = S.data_rain_graze_ss_m17;

    % ---- preallocate outputs ----
    SC_water_net     = cell(nR,nW,nG,nT);
    FC_water_net     = cell(nR,nW,nG,nT);
    SC_nitrogen_net  = cell(nR,nW,nG,nT);
    FC_nitrogen_net  = cell(nR,nW,nG,nT);
    GE_SC_water      = zeros(nR,nW,nG,nT);
    GE_FC_water      = zeros(nR,nW,nG,nT);
    GE_SC_nitrogen   = zeros(nR,nW,nG,nT);
    GE_FC_nitrogen   = zeros(nR,nW,nG,nT);

    % ---- WATER networks ----
    for ir = 1:nR
        for iw = 1:nW
            for ig = 1:nG
                D = data_rain_graze_ss_m17{Ridx(ir),Gidx(ig),iw};

                domfieldmap = D{4};               % dominant species map
                domfieldmap = domfieldmap(47:end,:,:); % drop warm-up
                plant       = D{1,1};
                grass       = squeeze(plant(47:end,:,:,1));
                shrub       = squeeze(plant(47:end,:,:,2));
                availWater  = D{5};

                for t = 1:nT
                    if mod(t,16)==0
                        fprintf('WATER  r=%d w=%d g=%d t=%3d/%3d\n',ir,iw,ig,t,nT);
                    end

                    dom = squeeze(domfieldmap(t,:,:))';  dom = dom(:);
                    gsp = squeeze(grass(t,:,:))';        gsp = gsp(:);
                    ssp = squeeze(shrub(t,:,:))';        ssp = ssp(:);

                    wava = squeeze(availWater(t+46,:,:,1))'; % +46 to match your indexing
                    wava = abs(wava(:));

                    % structural adjacency
                    A = zeros(fieldsize^2);
                    for x = removeboundary
                        if (ssp(x)<=shrubThr && gsp(x)<=grassThr)
                            A(x,x+fieldsize) = 1;
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize]) = [0.10 0.10 0.10 0.10];
                                A(x,[x+fieldsize+1 x+fieldsize-1])      = [0.05 0.05];
                            else
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize]) = [0.20 0.05 0.05 0.10];
                                A(x,[x+fieldsize+1 x+fieldsize-1])     = [0.05 0.05];
                            end
                        end
                    end
                    ANet = antisym_to_net(A);
                    Gsc  = digraph(ANet,'omitselfloops');
                    Gsc  = rmnode(Gsc,[1:fieldsize*boundry ...
                                  (fieldsize^2)-boundry*fieldsize+1:fieldsize^2 ...
                                  sidebound1 sidebound2]);
                    SC_water_net{ir,iw,ig,t} = Gsc;

                    % functional adjacency
                    A = zeros(fieldsize^2);
                    for x = removeboundary
                        if (ssp(x)<=shrubThr && gsp(x)<=grassThr)
                            A(x,x+fieldsize) = 1*wava(x);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize]) = 0.10*wava(x);
                                A(x,[x+fieldsize+1 x+fieldsize-1])      = 0.05*wava(x);
                            else
                                A(x,x-fieldsize) = 0.20*wava(x);
                                A(x,[x+1 x-1 x+fieldsize]) = 0.05*wava(x);
                                A(x,[x+fieldsize+1 x+fieldsize-1]) = 0.05*wava(x);
                            end
                        end
                    end
                    ANet = antisym_to_net(A);
                    Gfc  = digraph(ANet,'omitselfloops');
                    Gfc  = rmnode(Gfc,[1:fieldsize*boundry ...
                                  (fieldsize^2)-boundry*fieldsize+1:fieldsize^2 ...
                                  sidebound1 sidebound2]);
                    FC_water_net{ir,iw,ig,t} = Gfc;

                    GE_SC_water(ir,iw,ig,t) = mean( centrality(Gsc,'outcloseness','Cost',1./Gsc.Edges.Weight) ...
                                                  + centrality(Gsc,'incloseness','Cost',1./Gsc.Edges.Weight) );
                    GE_FC_water(ir,iw,ig,t) = mean( centrality(Gfc,'outcloseness','Cost',1./Gfc.Edges.Weight) ...
                                                  + centrality(Gfc,'incloseness','Cost',1./Gfc.Edges.Weight) );
                end
            end
        end
    end

    % ---- NITROGEN networks ----
    for ir = 1:nR
        for iw = 1:nW
            for ig = 1:nG
                D = data_rain_graze_ss_m17{Ridx(ir),Gidx(ig),iw};

                cvector     = D{8};          % [water, wind, cow] weights per time
                domfieldmap = D{4}; domfieldmap = domfieldmap(47:end,:,:);
                plant       = D{1,1};
                grass       = squeeze(plant(47:end,:,:,1));
                shrub       = squeeze(plant(47:end,:,:,2));

                availWaterN = D{5};  % (:,:,:,2) for nitrogen
                availWindN  = D{6};
                availCowN   = D{7};

                for t = 1:nT
                    if mod(t,16)==0
                        fprintf('NITROGEN r=%d w=%d g=%d t=%3d/%3d\n',ir,iw,ig,t,nT);
                    end
                    cvec = abs(cvector(t+45,:));

                    dom = squeeze(domfieldmap(t,:,:))'; dom = dom(:);
                    gsp = squeeze(grass(t,:,:))';       gsp = gsp(:);
                    ssp = squeeze(shrub(t,:,:))';       ssp = ssp(:);

                    naw = abs(squeeze(availWaterN(t+45,:,:,2))'); naw = naw(:);
                    nwi = abs(squeeze(availWindN (t+45,:,:,2))'); nwi = nwi(:);
                    nco = abs(squeeze(availCowN  (t+45,:,:,2))'); nco = nco(:);

                    % ---- Structural nitrogen
                    A = zeros(fieldsize^2);
                    for x = removeboundary
                        % water rule
                        if (ssp(x)<=shrubThr && gsp(x)<=grassThr)
                            A(x,x+fieldsize) = cvec(1);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize]) = A(x,[x-fieldsize x+1 x-1 x+fieldsize]) + 0.10*cvec(1);
                                A(x,[x+fieldsize+1 x+fieldsize-1])      = A(x,[x+fieldsize+1 x+fieldsize-1])      + 0.05*cvec(1);
                            else
                                A(x,x-fieldsize) = A(x,x-fieldsize) + 0.20*cvec(1);
                                A(x,[x+1 x-1 x+fieldsize]) = A(x,[x+1 x-1 x+fieldsize]) + [0.05 0.05 0.10]*cvec(1);
                                A(x,[x+fieldsize+1 x+fieldsize-1]) = A(x,[x+fieldsize+1 x+fieldsize-1]) + 0.05*cvec(1);
                            end
                        end
                        % wind rule
                        if (ssp(x)<=shrubThr)
                            A(x,x+fieldsize) = A(x,x+fieldsize) + cvec(2);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + [0.05 0.15 0.15 0.05 0.05 0.05]*cvec(2);
                            else
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + [0.05 0.05 0.05 0.30 0.05 0.05]*cvec(2);
                            end
                        end
                        % cow rule
                        if (ssp(x)>shrubThr && gsp(x)>grassThr)
                            A(x,x-fieldsize) = A(x,x-fieldsize) + cvec(3);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + 0.10*cvec(3);
                            else
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + 0.0625*cvec(3);
                            end
                        end
                    end
                    ANet = antisym_to_net(A);
                    Gsc  = digraph(upper(ANet),'omitselfloops'); % keep upper for consistency
                    Gsc  = rmnode(Gsc,[1:fieldsize*boundry ...
                                  (fieldsize^2)-boundry*fieldsize+1:fieldsize^2 ...
                                  sidebound1 sidebound2]);

                    % ---- Functional nitrogen
                    A = zeros(fieldsize^2);
                    for x = removeboundary
                        % water
                        if (ssp(x)<=shrubThr && gsp(x)<=grassThr)
                            A(x,x+fieldsize) = naw(x);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize]) = 0.10*naw(x);
                                A(x,[x+fieldsize+1 x+fieldsize-1])      = 0.05*naw(x);
                            else
                                A(x,x-fieldsize) = 0.20*naw(x);
                                A(x,[x+1 x-1 x+fieldsize]) = 0.05*naw(x);
                                A(x,[x+fieldsize+1 x+fieldsize-1]) = 0.05*naw(x);
                            end
                        end
                        % wind
                        if (ssp(x)<=shrubThr)
                            A(x,x+fieldsize) = A(x,x+fieldsize) + nwi(x);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + [0.05 0.15 0.15 0.05 0.05 0.05]*nwi(x);
                            else
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + [0.05 0.05 0.05 0.30 0.05 0.05]*nwi(x);
                            end
                        end
                        % cow
                        if (ssp(x)>shrubThr && gsp(x)>grassThr)
                            A(x,x-fieldsize) = A(x,x-fieldsize) + nco(x);
                        else
                            if dom(x)==1
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + 0.10*nco(x);
                            else
                                A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) = ...
                                    A(x,[x-fieldsize x+1 x-1 x+fieldsize x+fieldsize+1 x+fieldsize-1]) + 0.0625*nco(x);
                            end
                        end
                    end