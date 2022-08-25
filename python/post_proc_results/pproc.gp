reset

set title "Ratio n_{samp}/n_{prob} where multi method first better"
set style data linesp
unset log y
set log x
set ytics mirror
set y2range [0.0:0.22]
set yrange [0.0:0.22]
set ytics  (0.01,0.02,0.05,0.1,0.15,0.2)
set y2tics ("0.01" 0.01,0.02,0.05,0.1,0.15,0.2)
set ylabel "n_{samp}/n_{prob}"
set xlabel "n_{prob} (length of probability distribution)"
plot [1000:] 'ratio2.txt' title "nsamp / nprob", "ratio_no_Counts.txt" title "no conversion"

set out "samples1.pdf"
set term pdf
replot

set out "samples1.png"
set term png size 1280,960
replot

set out
set term qt
replot
