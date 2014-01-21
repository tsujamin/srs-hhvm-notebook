function [] = graph_percentage_surf( percentage )
%GRAPH_DATASET Summary of this function goes here

    [hhvmclean, hhvmbump, hhvmbumpnocount] = load_percentage_data ();
    
    graph(percentage, hhvmclean, hhvmbump, hhvmbumpnocount)
end

function [] = graph(percentage, hhvmclean, hhvmbump, hhvmbumpnocount)
     
    figure1 = figure('XVisual','','Renderer','OpenGL');
    %Set up graph:
    axes1 = axes('Parent',figure1,...
    'YTickLabel',{'200','400','600','800','1000','1200','1400','1600'},...
    'XTickLabel',{'40','80','120','160','200','240','280','320','360','400'});
    view(axes1,[-81.5 20]);
    grid(axes1,'on');
    hold(axes1,'all');
    
    hsurf = surf(hhvmclean(:,:,percentage),'Parent',axes1,'FaceColor',[1 0 0],'FaceAlpha',0.5,...
    'DisplayName','hhvmclean');
    hold on
    
    hsurf = surf(hhvmbump(:,:,percentage), 'Parent',axes1,'FaceColor',[0 1 0],'FaceAlpha',0.5,...
    'DisplayName','hhvmbump');
    hold on
        
    hsurf = surf(hhvmbumpnocount(:,:,percentage), 'Parent',axes1,'FaceColor',[0 0 1],'FaceAlpha',0.5,...
    'DisplayName','hhvmbumpnocount');
    % Create legend
    legend1 = legend(axes1,'show');
    set(legend1,...
    'Position',[0.808125 0.8240370274638 0.125390625 0.124426605504587]);

    %Axis Labels
    xlabel('Concurrent Requests');
    ylabel('Requests');
    zlabel([int2str(percentage), '% Response Time(ms)']);
end
