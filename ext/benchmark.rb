require 'tmpdir'
require 'webgen/utils/external_command'

Webgen::Utils::ExternalCommand.ensure_available!('gnuplot', '-v')

class HexaPDFBenchmark

  include Webgen::PathHandler::Base
  include Webgen::PathHandler::PageUtils

  def create_nodes(path, blocks)
    path.ext = 'svg'
    img_node = create_node(path) do |node|
      set_blocks(node, blocks)

      page_path = Webgen::Path.new(path.alcn.sub(/\.svg$/, '.page'), 'handler' => 'page',
                                  'title' => node['title'], 'modified_at' => node['modified_at'])
      name = path.basename
      readme = File.join(@website.config['path_handler.benchmark.base_dir'], name, 'README.md')
      readme = File.absolute_path(readme, @website.directory)

      blocks['content'] ||= <<~TEXT
        <webgen:block name="readme" />

        ## Results

        These benchmark results are from **{date: {mi: modified_at, format: "%Y-%m-%d"}}**.

        ![benchmark graphic](#{node.alcn})
        {:.image.fit style="text-align: center"}

        <div markdown="1" class="bmtable">
        <webgen:block name="data" />
        </div>
      TEXT
      blocks['readme'] = File.read(readme)
      content = Webgen::Page.new({'title' => node['title']}, blocks).to_s
      page_node = @website.ext.path_handler.create_secondary_nodes(page_path, content).first
      @website.ext.item_tracker.add(page_node, :file, readme)
      @website.ext.item_tracker.add(page_node, :node_content, node)
    end
  end

  def content(node)
    name = node.cn.sub(/\..*$/, '')
    bmdir = File.absolute_path(File.join(@website.config['path_handler.benchmark.base_dir']),
                               @website.directory)

    src_file = '/tmp/plot.src'
    File.write(src_file, node.blocks['data'])
    execute("cat #{src_file} | ruby generate_plot_data.rb > /tmp/plot_#{name}.data", bmdir)

    cfg_file = '/tmp/plot.cfg'
    svg_file = '/tmp/plot.svg'
    File.write(cfg_file, <<~TEXT)
      set terminal svg fname 'Verdana, Helvetica, Arial, sans-serif'
      set output '#{svg_file}'
      load "plot.cfg"
    TEXT
    cmd = "gnuplot #{cfg_file}"
    execute("gnuplot #{cfg_file}", File.join(bmdir, name))

    File.read(svg_file)
  end

  def execute(cmd, cwd)
    status, stdout, stderr = systemu(cmd, cwd: cwd)
    if status.exitstatus != 0
      raise Webgen::RenderError.new("Error while running a command for benchmark: #{stdout + "\n" + stderr}",
                                    'path_handler.benchmark')
    end
  end

end
