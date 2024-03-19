function save_fig(output_folder,fig_name)
    full_fig_name = fullfile(output_folder,fig_name);
    ax = gca;
    exportgraphics(ax,full_fig_name)    
end