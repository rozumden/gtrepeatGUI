function clustGUI()
%# Create the figure window and show the image.
hFigure = figure;
init_toolbar();
hToolbar = findall(hFigure,'Type','uitoolbar');
% Make next grid button
next_icon = imresize(imread('next.png'),[16 16]);
make_icon = imresize(imread('make.png'),[16 16]);
estimate_icon = imresize(imread('estimate.png'),[16 16]);
uitoggletool(hToolbar, ...
    'ClickedCallback', @toggle_make_clust_callback, ...
    'CData', make_icon, ...
    'TooltipString','Paint truth and annotations', ...
    'Tag','make_clust');
uitoggletool(hToolbar, ...
    'ClickedCallback', @toggle_next_grid_callback, ...
    'CData', next_icon, ...
    'TooltipString','Go to the next grid', ...
    'Tag','next_grid');
uitoggletool(hToolbar, ...
    'ClickedCallback', @toggle_estimate_callback, ...
    'CData', estimate_icon, ...
    'TooltipString','Estimate the truth', ...
    'Tag','estimate');
jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
uistate = struct;
uistate.handles = guihandles(hFigure);
if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.make_clust = handle(jCombo,'CallbackProperties');
    set(uistate.handles.make_clust, 'Visible', 0);
    set(uistate.handles.make_clust, 'ActionPerformedCallback', @toggle_make_clust_callback);
    jToolbar(1).add(jCombo,1); % 1 icon after pan icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end
if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.next_grid = handle(jCombo,'CallbackProperties');
    set(uistate.handles.next_grid, 'Visible', 0);
    set(uistate.handles.next_grid, 'ActionPerformedCallback', @toggle_next_grid_callback);
    jToolbar(1).add(jCombo,2); % 2 icon after pan icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end
if ~isempty(jToolbar)
    jCombo = javax.swing.JComboBox();
    uistate.handles.estimate = handle(jCombo,'CallbackProperties');
    set(uistate.handles.estimate, 'Visible', 0);
    set(uistate.handles.estimate, 'ActionPerformedCallback', @toggle_estimate_callback);
    jToolbar(1).add(jCombo,3); % 3 icon after pan icon
    jToolbar(1).repaint;
    jToolbar(1).revalidate;
end
set(0,'showhiddenhandles','on')
uistate.sql = SqlDb;
uistate.sql.open('cfg_file', ...
       '~/src/cvdb/sqldbcfgs/lcraid_sqldb.cfg');
uistate.imagedb = ImageDb('cfg_file', ...
                  '~/src/cvdb/casscfgs/lascarremote.cfg');
uistate.img_set = uistate.sql.get_img_set('cvpr15/annotations');
uistate.propose_params = { ...
    'app_thresh', 0.3, ... 
    'app_knn', 5, ...
    'merge_app_clusters', true, ...    
    'num_linfs', 1000, ...
    'cluster_linfs', true};
guidata(gcf,uistate);


function [] = open_file_callback(hObject, eventdata)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);
figure();
axes('Units','pixels');
popup = uicontrol('Style', 'listbox',...
       'String', {uistate.img_set(:).url},...
       'Position', [1 1 1000 500],...
       'Callback', @process_image);
guidata(gcf,uistate);


function process_image(source,callbackdata)
uistate = guidata(gcf);
uistate.cur_image = get(source,'Value');
close; % close popup
k = uistate.cur_image;
uistate.cache = ImageCache(uistate.img_set(k).cid, ...
                   uistate.imagedb);
uistate.img = DR.Img('data',uistate.cache.get_img(), ...
                     'cid',uistate.img_set(k).cid, ...
                     'url',uistate.img_set(k).url);
uistate.cache.add_dependency('planar_regions',[]);
uistate.plane_list = uistate.cache.get('annotations','planar_regions');
uistate.handles.img = image(uistate.img.data);
axis off;
set(uistate.handles.img,'HitTest','on');
set(uistate.handles.img,'ButtonDownFcn',@image_click_callback);
[uistate.mser, uistate.dr] = get_dr(uistate.img,uistate.cache);
uistate.propose = Propose(uistate.img,uistate.propose_params{:});
uistate.propose.set_dr(uistate.mser);
[uistate.app_clusters,~] = uistate.propose.make_app_clusters();
uistate.labels = zeros(1,numel(uistate.mser)); 
for i = 1:numel(uistate.app_clusters)
  uistate.labels(uistate.app_clusters(i).sites) = i;
end
uistate.cur_plane = 1;
uistate.cur_repeat = 1;
uistate.cur_grid = 0;
guidata(gcf,uistate);


function [] = save_file_callback(hObject, eventdata)
uistate = guidata(gcf);
h = errordlg('Saving(not supported yet)');
pause(0.5);
delete(h);
guidata(gcf, uistate);


function image_click_callback(hImg, eventdata)
uistate = guidata(gcf);
h = errordlg('Image click(not supported yet)');
pause(0.5);
delete(h);
guidata(gcf,uistate);


function toggle_estimate_callback(hCombo, eventdata)
uistate = guidata(gcf);
h = findobj(gcf,'-property','BrushData');
brush = get(h, 'BrushData');
xd = get(h, 'XData');
yd = get(h, 'YData');
if isempty(brush)
  h = errordlg('Choose points!');
  pause(0.5);
  delete(h);
  return;
end
n = sum(uistate.labels > 0);
if numel(brush) < n
  h = errordlg('Choose points!');
  pause(0.5);
  delete(h);
  return;
end
brush = brush(end - n + 1:end); % Get rid of annotation handles
brush = [brush{:}];
brush = reshape(brush,[3,n]);
brush = logical(sum(brush)); % was point chosen or not
dru = [uistate.mser(:).u];
if isfield(uistate,'p1') & uistate.p1 ~= 0
  dru = dru - uistate.p;
end
xd = xd(end - n + 1:end); % Get rid of annotation xd
xd = [xd{:}];
xd = reshape(xd,[3,n]);

yd = yd(end - n + 1:end); % Get rid of annotation yd
yd = [yd{:}];
yd = reshape(yd,[3,n]);
pts = cat(1,xd(1,brush),yd(1,brush));
ind = [];
for i = 1:size(pts,2)
  icoord = find((pts(1,i) == dru(1,:)) + (pts(1,i) == dru(4,:)) + (pts(1,i) == dru(7,:)));
  jcoord = find((pts(2,i) == dru(2,:)) + (pts(2,i) == dru(5,:)) + (pts(2,i) == dru(8,:)));
  if ~isempty(icoord) & ~isempty(jcoord) 
    ind = cat(2,ind,intersect(icoord,jcoord));
  end
end

lab = zeros(1,numel(uistate.mser));
lab(ind) = uistate.labels(ind);
imshow(uistate.patch);
LAF.draw_repeats(gca, dru , lab, 'exclude', 0);
guidata(gcf,uistate);
linf = find_linf(lab);


function H = find_linf(labels)
uistate = guidata(gcf);
mu = [uistate.mser(:).mu]; 
sc = [uistate.mser(:).sc];
l = unique(labels);
l = l(2:end);
mask = [1:numel(labels)];
for i = 1:numel(l)
  ind = labels == l(i);
  aX{i} = mu(:,ind);
  asc{i} = sc(ind);
  laf_groups{i} = mask(ind);
end
H = HG.linf_from_2x2laf.estimate(aX,asc); 
dru = [uistate.mser(:).u];
% H = lafmxn_to_H(dru,laf_groups,H);
v = LAF.renormI(blkdiag(H,H,H)*dru);
A = HG.A_from_1laf([v;dru]); 
rimg = IMG.rectify(uistate.img.data,A*H);
image(rimg);
guidata(gcf,uistate);


function toggle_next_grid_callback(hCombo, eventdata)
uistate = guidata(gcf);
if ~isfield(uistate, 'cur_plane')
  h = errordlg('Image is not selected!');
  pause(0.5);
  delete(h);
  return;
end  
if uistate.cur_plane > numel(uistate.plane_list)
  imshow(uistate.img.data);
  uistate.cur_plane = 1;
  uistate.cur_repeat = 1;
  uistate.cur_grid = 0;
  h = errordlg('No more grids!');
  pause(0.5);
  delete(h);
  guidata(gcf, uistate);
  return;
end
if uistate.cur_repeat > numel(uistate.plane_list(uistate.cur_plane).repeat_list)
  uistate.cur_plane = uistate.cur_plane + 1;
  uistate.cur_repeat = 1;
  uistate.cur_grid = 0;
  guidata(gcf, uistate);
  toggle_next_grid_callback(hCombo, eventdata);
  return;
end
if ~uistate.plane_list(uistate.cur_plane).has_grid
  uistate.cur_plane = uistate.cur_plane + 1;
  uistate.cur_repeat = 1;
  uistate.cur_grid = 0;
  guidata(gcf, uistate);
  toggle_next_grid_callback(hCombo, eventdata);
  return;
end
uistate.cur_grid = uistate.cur_grid + 1;
repeat = uistate.plane_list(uistate.cur_plane).repeat_list(uistate.cur_repeat);
if isempty(repeat.grids) | uistate.cur_grid > max(repeat.grids)
  uistate.cur_repeat = uistate.cur_repeat + 1;
  uistate.cur_grid = 0;
  guidata(gcf, uistate);
  toggle_next_grid_callback(hCombo, eventdata);
  return;
end
polys = repeat.poly(repeat.grids == uistate.cur_grid); 
coord = [polys(:).x];
if isempty(coord)
  guidata(gcf, uistate);
  toggle_next_grid_callback(hCombo, eventdata);
  return;
end
x = coord(1,:);
y = coord(2,:);
uistate.patch = uistate.img.data(min(y):max(y),min(x):max(x),:);
imshow(uistate.patch);
edges = find_edges(coord);
edges = cat(2,edges,edges(:,1));
dru = [uistate.mser(:).u];
uistate.p1 = min(x) - 1;
uistate.p2 = min(y) - 1;
p = [uistate.p1; uistate.p2; 0]; 
p = repmat(p, [3 size(dru,2)]);
uistate.p = p;
ind = 1:numel(dru);
in = ind(find(inpolygon(dru(4,:),dru(5,:), ...
                 edges(1,:),edges(2,:))));
dru = dru - p;
LAF.draw_repeats(gca, dru, uistate.labels, 'exclude', 0);
for k = 1:numel(polys)
  hold on;
  plot(gca, [polys(k).x(1,:)-p(1,1) polys(k).x(1,1)-p(1,1)], ...
       [polys(k).x(2,:)-p(2,1) polys(k).x(2,1)-p(2,1)], 'LineWidth',3);
  hold off;
end
guidata(gcf, uistate);


function toggle_make_clust_callback(hCombo, eventdata)
uistate = guidata(gcf);
if isfield(uistate, 'cur_image')
  uistate.p1 = 0;
  uistate.p2 = 0;
  imshow(uistate.img.data);
  LAF.draw_repeats(gca, [uistate.mser(:).u], uistate.labels, 'exclude', 0);
  mpdc = distinguishable_colors(numel(uistate.plane_list));
  for k2 = 1:numel(uistate.plane_list)
        for k3 = 1:numel(uistate.plane_list(k2).repeat_list)
            for k4 = 1:numel(uistate.plane_list(k2).repeat_list(k3).poly)
                hold on;
                if (uistate.plane_list(k2).repeat_list(k3).poly(k4).is_grid)
                    color = 0.5*mpdc(k2,:);
                else
                    color = mpdc(k2,:);
                end

                plot(gca, ...
                     [uistate.plane_list(k2).repeat_list(k3).poly(k4).x(1,:) ...
                      uistate.plane_list(k2).repeat_list(k3).poly(k4).x(1,1)], ...
                     [uistate.plane_list(k2).repeat_list(k3).poly(k4).x(2,:) ...
                     uistate.plane_list(k2).repeat_list(k3).poly(k4).x(2,1)], ...
                     'Color',color,'LineWidth',3);
                hold off;
            end
        end
    end
  uistate.cur_plane = 1;
  uistate.cur_repeat = 1;
  uistate.cur_grid = 0;
else
  h = errordlg('Image is not selected!');
  pause(0.5);
  delete(h);
end  
guidata(gcf, uistate);


function init_toolbar()
a = findall(gcf);
b = findall(a,'ToolTipString','Rotate 3D');
set(b,'Visible','Off');

% b = findall(a,'ToolTipString','Brush/Select Data');
% set(b,'Visible','Off');

b = findall(a,'ToolTipString','Rotate 3D');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Insert Colorbar');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Insert Legend');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Link Plot');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Print Figure');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Hide Plot Tools');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Show Plot Tools');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Show Plot Tools and Dock Figure');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Edit Plot');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Data Cursor');
set(b,'Visible','Off');

b = findall(a,'ToolTipString','Open File');
set(b,'ClickedCallback',@open_file_callback);

b = findall(a,'ToolTipString','Save Figure');
set(b,'ClickedCallback',@save_file_callback);

function edges = find_edges(polys);
    x = polys(1,:);
    y = polys(2,:);
    edges = [];
    edges = cat(2,edges,[polys(:,1); 1]);
    edges = cat(2,edges,[polys(:,end-1); 1]);
    [m,n] = size_of_grid(polys);
    edges = cat(2,edges,[polys(:,4*(m-1)+2); 1]);
    edges = cat(2,edges,[polys(:,end-4*(m-1)); 1]);

function [m,n] = size_of_grid(polys)
    m = 1;
    t = 1;
    p = 0;
    n = 0;
    while p <= size(polys,2)-8
        while p <= size(polys,2)-8 & polys(:,p + 2) == polys(:,p+5) & ...
                                  polys(:,p + 3) == polys(:,p+8) 
            p = p + 4;
            t = t + 1;
            if t > m, m = t; end
        end
        t = 1;
        p = p + 4;
        n = n + 1;
    end
    if p <= size(polys,2)-4
        n = n + 1;
    end
