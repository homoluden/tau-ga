#encoding: utf-8
require 'rubygems'
require 'gnuplot'

class SSPlotter
  def SSPlotter.draw_one_dataset (title, xlabel, ylabel, draw_with, x, y )
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.title  title
        plot.ylabel ylabel
        plot.xlabel xlabel

        SSPlotter.plot_dataset(plot,draw_with,x,y)
      end
    end
  end
  def SSPlotter.draw_multy_dataset (title, xlabel, ylabel, draw_with, x, yy )
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.title  title
        plot.ylabel ylabel
        plot.xlabel xlabel

        SSPlotter.plot_multy_dataset(plot,draw_with,x,yy)
      end
    end
  end
  def SSPlotter.plot_dataset(plot,with,x,y)
    plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
      ds.with = with
      ds.notitle
    end
  end
  def SSPlotter.plot_multy_dataset(plot,with,x,yy)
    yy.each { |y| plot_dataset(plot,with,x,y) }
  end
end
