mkdir output
vivado -jou ./output/vivado.jou -log ./output/vivado.log -mode batch -source ./tcl/synth.tcl
vivado -jou ./output/vivado.jou -log ./output/vivado.log -mode batch -source ./tcl/program.tcl
# i do not want this log if everything is fine
rm -r ./output ./amba_digitherm.cache ./amba_digitherm.hw ./amba_digitherm.ip_user_files ./.Xil
rm usage_statistics_webtalk.html usage_statistics_webtalk.xml
