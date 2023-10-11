import os
import argparse
import subprocess
from pandas import read_csv
from pandas import DataFrame
from pandas import Grouper
from matplotlib import pyplot as plt
import pandas as pd

def plot(axes, csv_file, put, cut_off, step, ticks, idx):
	#Read the results
	df = read_csv(csv_file)
	runs = 5
	mean_list = []
	x=idx//5
	y=idx%5
	min_y=100000
	max_y=0

	for subject in [put]:
		for fuzzer in ['aflnet', 'aflnwe', 'stateafl', 'HNPFuzzer']:
			df1 = df[(df['subject'] == subject.lower()) & 
						 (df['fuzzer'] == fuzzer) & (df['cov_type'] == 'b_abs')]
			mean_list.append((subject, fuzzer, 0, 0.0))
			for time in range(1, cut_off + 1, step):
				cov_total = 0
				run_count = 0

				for run in range(1, runs + 1, 1):
					df2 = df1[df1['run'] == run]
					start = df2.iloc[0, 0]
					df3 = df2[df2['time'] <= start + time*60]
					cov_total += df3.tail(1).iloc[0, 5]
					run_count += 1
				
				avg_cov = cov_total / run_count
				if(time == 1 and avg_cov < min_y):
					min_y = avg_cov
				if(time == cut_off and avg_cov > max_y):
					max_y = avg_cov

				#add a new row
				mean_list.append((subject, fuzzer, time, avg_cov))

	#Convert the list to a dataframe
	mean_df = pd.DataFrame(mean_list, columns = ['subject', 'fuzzer', 'time', 'branches'])

	soften = 100
	while(soften > max_y//10):
		soften //= 10
	markers = ['x', '|', '.', 'v']
	i = 0
	for key, grp in mean_df.groupby(['fuzzer'], sort=False):
		#print(type(grp['time']))
		if(cut_off>100):
			axes[x,y].plot(grp['time'], grp['branches'], marker=markers[i], markevery=ticks//3, markersize=6)
		else:
			axes[x,y].plot(grp['time'], grp['branches'], marker=markers[i], markersize=6)
		axes[x,y].set_xticks(range(0,cut_off+1,ticks))
		axes[x,y].set_xlabel('Time (min)')
		axes[x,y].set_ylim([max(0,min_y-soften),max_y+soften])
		
		if(y==0):
			axes[x,y].set_ylabel('#branches')
		axes[x,y].set_title(put)
		i+=1

def exec_cmd(cmd,env={}):
	p=subprocess.Popen(cmd, shell=True, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	stdout, stderr = p.communicate()

def gen_csv(target_path,PFBENCH):
	root=os.getcwd()
	scripts_path=f"{PFBENCH}/scripts/analysis"
	rm_others="rm `ls | grep -v \"out\"`"
	gen_all="profuzzbench_generate_all.sh"
	env=dict(os.environ)
	env['PATH']=f"{env['PATH']}:{scripts_path}"
	os.chdir(target_path)
	exec_cmd(rm_others)
	print("start generating csv in {}".format(target_path))
	exec_cmd(gen_all,env)
	os.chdir(root)

def main(cut_off,step,ticks,out_file,csv_path):
	ori_path = os.getcwd()
	fig, axes = plt.subplots(3, 5, figsize = (20, 10))
	in_fmt="{}/{}/results.csv"

	PFBENCH=os.getenv("PFBENCH")
	if(not PFBENCH):
		print("$PFBENCH is empty")
		exit(1)
	path = os.path.join(PFBENCH,"subjects")
	os.chdir(path)
	
	idx=0
	protocols=os.listdir(path)
	for protocol in protocols:
		sub_path=os.path.join(path,protocol)
		if(os.path.isfile(sub_path)):
			continue
		subjects=os.listdir(sub_path)
		for subject in subjects:
			sub_path2=os.path.join(sub_path,subject)
			if(os.path.isfile(sub_path2)):
				continue
			print(subject)
			if(subject=="PureFTPD"):
				subject="pure-ftpd"
			if(not csv_path):
				gen_csv(os.path.join(sub_path2,"results"),PFBENCH) # the relative path of generated results.csv is "results" by default
				plot(axes,in_fmt.format(sub_path2,"results"),subject,cut_off,step,ticks,idx)
			else:
				plot(axes,in_fmt.format(sub_path2,csv_path),subject,cut_off,step,ticks,idx)
			idx+=1
	plt.delaxes(axes[2, 3])
	plt.delaxes(axes[2, 4])
	for i, ax in enumerate(fig.axes):
		ax.grid(linewidth = 0.2)
	plt.legend(bbox_to_anchor=(2.6, 0.85), labels=['AFLNet', 'AFLNwe', 'StateAFL', 'HNPFuzzer'], fontsize = '20')
	fig.tight_layout()
	plt.subplots_adjust(wspace = 0.25, hspace = 0.3)
	
	os.chdir(ori_path)
	plt.savefig(out_file)

if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('-c','--cut_off',type=int,required=True,help="Cut-off time in minutes")
	parser.add_argument('-s','--step',type=int,required=True,help="Time step in minutes")
	parser.add_argument('-t','--ticks',type=int,required=True,help="Ticks of x axis")
	parser.add_argument('-o','--out_file',type=str,required=True,help="Output file")
	parser.add_argument('-r','--results_csv',type=str,required=False,default=None,help="Relative path of results.csv")
	args = parser.parse_args()
	main(args.cut_off, args.step, args.ticks, args.out_file, args.results_csv)
