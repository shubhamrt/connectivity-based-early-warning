function [ax,h]=suplabel(text,whichLabel,mar,keep,inter)
% PLaces text as a title, xlabel, or ylabel on a group of subplots.
% Returns a handle to the label and a handle to the axis.
%  [ax,h]=suplabel(text,whichLabel,mar)
% returns handles to both the axis and the label.
%  ax=suplabel(text,whichLabel,supAxes)
% returns a handle to the axis only.
%  suplabel(text) with one input argument assumes whichLabel='x'
%
% whichLabel is any of 'x', 'y', 'yy', or 't', specifying whether the
% text is to be the xlable, ylabel, right side y-label,
% or title respectively.
%
% mar is an optional argument specifying the margin from the axes of the
%  "super" axes surrounding the subplots.
%  mar defaults to 0.04
%  specify supAxes if labels get chopped or overlay subplots
%
% EXAMPLE:
%  subplot(2,2,1);ylabel('ylabel1');title('title1')
%  subplot(2,2,2);ylabel('ylabel2');title('title2')
%  subplot(2,2,3);ylabel('ylabel3');xlabel('xlabel3')
%  subplot(2,2,4);ylabel('ylabel4');xlabel('xlabel4')
%  [ax1,h1]=suplabel('super X label');
%  [ax2,h2]=suplabel('super Y label','y');
%  [ax3,h2]=suplabel('super Y label (right)','yy');
%  [ax4,h3]=suplabel('super Title'  ,'t');
%  set(h3,'FontSize',30)
%
% SEE ALSO: text, title, xlabel, ylabel, zlabel, subplot,
%           suptitle (Matlab Central)

% Author: Ben Barrowes <barrowes@alum.mit.edu>
% Updated by Durga Lal Shrestha for more flexible way to margin (9/11/2013)

%modified 3/16/2010 by IJW to make axis behavior re "zoom" on exit same as
%at beginning. Requires adding tag to the invisible axes

%% -------------------------------------------------------------------------
if nargin < 2, whichLabel = 'x';  end
if nargin < 1, help(mfilename); return; end

if ~isstr(text) | ~isstr(whichLabel)
    error('text and whichLabel must be strings')
end
whichLabel=lower(whichLabel);
if nargin <4
    keep = false;
end
if nargin >=4 && isempty(keep)
    keep = false;
end
if nargin <5
    inter = 'none';
end
    
%%  remove if existing suplabel) added by Durga (27/08/2014),
if ~keep
    if strcmp('t',whichLabel)
        curr_suplabel = findobj(gcf,'type','axes','tag','suplabel_t');
    elseif strcmp('x',whichLabel)
        curr_suplabel = findobj(gcf,'type','axes','tag','suplabel_x');
    elseif strcmp('y',whichLabel)
        curr_suplabel = findobj(gcf,'type','axes','tag','suplabel_y');
    elseif strcmp('yy',whichLabel)
        curr_suplabel = findobj(gcf,'type','axes','tag','suplabel_yy');
    end
    delete(curr_suplabel)
end
%%
currax=findobj(gcf,'type','axes','-not','tag','suplabel');
%supAxes=[.08 .08 .84 .84];

if nargin < 3 || (nargin >3 && isempty(mar))
    mar=0.0;
end
ah=findall(gcf,'type','axes');
if ~isempty(ah)
    supAxes=[inf,inf,0,0];
    leftMin=inf;  bottomMin=inf;  leftMax=0;  bottomMax=0;
    axBuf=.04;
    set(ah,'units','normalized')
    ah=findall(gcf,'type','axes');
    for ii=1:length(ah)
        if strcmp(get(ah(ii),'Visible'),'on')
            thisPos=get(ah(ii),'Position');
            leftMin=min(leftMin,thisPos(1));
            bottomMin=min(bottomMin,thisPos(2));
            leftMax=max(leftMax,thisPos(1)+thisPos(3));
            bottomMax=max(bottomMax,thisPos(2)+thisPos(4));
        end
    end
    %   supAxes=[leftMin-axBuf,bottomMin-axBuf,leftMax-leftMin+axBuf*2,bottomMax-bottomMin+axBuf*2];
    %   % additional argumuent to fix labels get chopped or overlay subplots
    %   supAxes=[leftMin-marx,bottomMin-mary,leftMax-leftMin+axBuf*2,bottomMax-bottomMin+axBuf*2];
end




if strcmp('t',whichLabel)
    supAxes=[leftMin-axBuf,bottomMin-mar,leftMax-leftMin+axBuf*2,bottomMax-bottomMin+mar*2];
elseif strcmp('x',whichLabel)
    supAxes=[leftMin-axBuf,bottomMin-mar,leftMax-leftMin+axBuf*2,bottomMax-bottomMin+mar*2];
elseif strcmp('y',whichLabel)
    supAxes=[leftMin-mar,bottomMin-axBuf,leftMax-leftMin+mar*2,bottomMax-bottomMin+axBuf*2];
elseif strcmp('yy',whichLabel)
    supAxes=[leftMin-mar,bottomMin-axBuf,leftMax-leftMin+mar*2,bottomMax-bottomMin+axBuf*2];
end

%ax=axes('Units','Normal','Position',supAxes,'Visible','off','tag','suplabel');
if strcmp('t',whichLabel)
    ax=axes('Units','Normal','Position',supAxes,'Visible','off','tag','suplabel_t');
    set(get(ax,'Title'),'Visible','on')
    title(text,'interpreter',inter);
elseif strcmp('x',whichLabel)
    ax=axes('Units','Normal','Position',supAxes,'Visible','off','tag','suplabel_x');
    set(get(ax,'XLabel'),'Visible','on')
    xlabel(text,'interpreter',inter);
elseif strcmp('y',whichLabel)
    ax=axes('Units','Normal','Position',supAxes,'Visible','off','tag','suplabel_y');
    set(get(ax,'YLabel'),'Visible','on')
    ylabel(text,'interpreter',inter);
elseif strcmp('yy',whichLabel)
    ax=axes('Units','Normal','Position',supAxes,'Visible','off','tag','suplabel_yy');
    set(get(ax,'YLabel'),'Visible','on')
    ylabel(text,'interpreter',inter);
    set(ax,'YAxisLocation','right')
end

visible = get(gcf,'visible');
if strcmp(visible,'on')
    for k=1:length(currax), axes(currax(k));end % restore all other axes
else
    for k=1:length(currax), set(gcf,'CurrentAxes',currax(k));end % restore all other axes
end

if (nargout < 2)
    return
end
if strcmp('t',whichLabel)
    h=get(ax,'Title');
    set(h,'VerticalAlignment','middle')
elseif strcmp('x',whichLabel)
    h=get(ax,'XLabel');
elseif strcmp('y',whichLabel) | strcmp('yy',whichLabel)
    h=get(ax,'YLabel');
end

%%%ah=findall(gcf,'type','axes');
%%%'sssssssss',kb