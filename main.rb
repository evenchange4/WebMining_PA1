### ruby 2.0.0p0

### read argument
require 'optparse'
$options = {}
OptionParser.new do |opts|
	opts.on("-r")                       { |s| $options[:r] = true }
	opts.on("-i", '-i INPUT', "input ") { |s| $options[:i] = s } # ./queries/origin/query-5.xml
	opts.on("-o", '-o OUTPUT',"output") { |s| $options[:o] = s } # ans
	opts.on("-m", '-m MODEL', "model ") { |s| $options[:m] = s } # ./model-files
	opts.on("-d", '-d NTCIR', "ntcir ") { |s| $options[:d] = s } # /tmp2/CIRB010
end.parse!
$dir_queryfile = File.dirname($options[:i]) 
puts $options
### end read argument


load "method.rb"

### convert strucure
if !Dir.exist?("#{$options[:m]}/inverted-index_converted") # "./model-files/inverted-index_converted/
	Convert_InvertedIndexFile()
else
	puts "The Inverted-index Structure has converted already."
end
$dictionary = eval(File.open("#{$options[:m]}/inverted-index_converted/0_dictionary", "rb").read)
### end convert strucure

### caculate idf for bm25 normalize useage
$file_list  = File.open("#{$options[:m]}/file-list", "rb").readlines
$doclen = Array.new
$file_list.each_with_index do |file, index|
	file = "#{$options[:d]}/.#{file}"
	$doclen[index] = File.size(file.strip)
end
$avgdoclen = $doclen.inject(0.0){ |sum, element| sum += element } / $doclen.size
###

### query parse
if !Dir.exist?("#{$dir_queryfile}/queries_converted") # "./model-files/inverted-index_converted/0_dictionary"
	ParseQuery(2) # 2 for bigram only
end
###

### scoring & output result
n = $options[:i].split("-")[1].split(".")[0].to_i

if $options[:r] # relevance feedback
	ans_f    = File.open("./#{$options[:o]}-#{n}", 'w')
	ans_f_fb = File.open("./#{$options[:o]}-#{n}-feedback", 'w')
	# each query
	(1..n).each do |i| 
		### q
		puts "Scoring query#{i}_ngram.all..."
		scores_hash = FastCosineScore(i) # return Scores Hash
		scores_topk = PickTopK(scores_hash, 100) # top 100 as output
		scores_topk.each do |documentid|
			file_name = $file_list[documentid].split("/")[4].downcase
			ans_f << "00#{i} #{file_name}"
		end # end each query of top K result

		### q + Rocchio feedback
		scores_merge_hash = scores_hash
		scores_merge_topk = scores_topk
		(1..4).each do |j|	# feedback j times
			puts "Scoring query#{i}_ngram.all with Rocchio... in loop #{j} ..."
			scores_R_hash = Rocchio(i, scores_merge_hash, scores_merge_topk, 4)    # top K = 2 as feedback
			scores_merge_hash = scores_R_hash.merge(scores_merge_hash){|key, oldval, val_R| 0.5*val_R + 0.5*oldval}	 # h1.merge(h2){|key, h2, h1| 0.5*h1 + h2}
			scores_merge_topk = PickTopK(scores_merge_hash, 100) # top 100 as output
		end
		
		scores_merge_topk.each do |documentid|
			file_name = $file_list[documentid].split("/")[4].downcase
			ans_f_fb << "00#{i} #{file_name}"
		end # end each query of top K result

	end # end each query 
	ans_f.close()
	ans_f_fb.close()	
else
	ans_f    = File.open("./#{$options[:o]}-#{n}", 'w')
	# each query
	(1..n).each do |i| 
		### q
		puts "Scoring query#{i}_ngram.all..."
		scores_hash = FastCosineScore(i) # return Scores Hash
		scores_topk = PickTopK(scores_hash, 100) # top 100 as output
		scores_topk.each do |documentid|
			file_name = $file_list[documentid].split("/")[4].downcase
			ans_f << "00#{i} #{file_name}"
		end # end each query of top K result
	end # end each query 
	ans_f.close()
end
