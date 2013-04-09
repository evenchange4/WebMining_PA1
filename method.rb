### structure convert, input path of model-files, ouput X
def Convert_InvertedIndexFile()
	Dir.mkdir("#{$options[:m]}/inverted-index_converted")
	puts "converting..."
	# 助教給的 inverted_index file
	$inverted_index = File.open("#{$options[:m]}/inverted-index", "rb")
	# 放在memory 做search用的 dictionary
	dictionary_hash = Hash.new

	current_line = $inverted_index
	begin 
		inverted_index_hash_value = Hash.new
		# 讀檔 block 第一行 [ vocab_id_1 vocab_id_2 df ]
		current_line = $inverted_index.readline
		temp_split = current_line.split(" ")
		vocab_id_1 = temp_split[0]
		vocab_id_2 = temp_split[1]
		ngram_df   = temp_split[2].to_i
		# 把 vocab_id_1_vocab_id_2 當作 key "dictionary"
		p dictionary  = "#{vocab_id_1}_#{vocab_id_2}"
		# new term file 放在 disk
		dictionary_f = File.open("#{$options[:m]}/inverted-index_converted/#{dictionary}", 'w')
		# vocab_id_1_vocab_id_2 as key 放在 memory
		dictionary_hash[dictionary] = ngram_df
		# postings list
		posting_list_hash = Hash.new
		(1..ngram_df).each do
			# 讀檔 block 其餘行 [ document tf ]
			current_line = $inverted_index.readline
			temp_split = current_line.split(" ")
			document_id = temp_split[0].to_i # document_id
			document_tf = temp_split[1].to_i # tf
			# 轉換 hash data stucture
			posting_list_hash[document_id] = document_tf
		end
		# write file
		dictionary_f.write(posting_list_hash)
		dictionary_f.close()

	end until $inverted_index.eof?
	# write file 做 search 用的 dictionary
	dictionary_hash_f = File.open("#{$options[:m]}/inverted-index_converted/0_dictionary", 'w')
	dictionary_hash_f.write(dictionary_hash)
	dictionary_hash_f.close()
	puts "converting done."
end
### 

### Score similarty, input merged ngram query lines array, ouput scores Hash
def FastCosineScore(queryi)
	queryi_ngram_all = File.open("#{$dir_queryfile}/queries_converted/query#{queryi}_ngram.all", "r").readlines
	scores = Hash.new{0} # Scores[N] 初始值 0
	# length_d = Hash.new{1} # Length[N] 初始值 0 document length
	# length_q = Hash.new{1} # Length[N] 初始值 0 query    length

	### parse each line
	queryi_ngram_all.each do |line|
		# 用空白 去 splite 每一行 產生 [ngram, 次數] 的 array
		temp_split = line.split(" ")       
		query_term = temp_split[0].split("\_") # ngram
		tf_q  = temp_split[1].to_i             # tf
		# puts "#{query_term} => (tf) #{query_tf} times"

		# process query term	
		# alpha = 0.2
		# beta = 1 - alpha
		# corpus_size = 97445 # corpus size	
		# if query_term.count == 1
		# 	query_term = query_term << "-1"
		# 	query_term = "#{query_term[0]}_#{query_term[1]}"
		# 	#### caculate scores
		# 	if $dictionary.has_key?(query_term)
		# 		df  = $dictionary[query_term]
		# 		idf = Math.log10(corpus_size/df) # df
		# 		# TF-IDF of query
		# 		w_q = tf_q * idf
		# 		posting_list = eval(File.open("./model-files/inverted-index_hash/#{query_term}", "rb").read)
		# 		posting_list.each do |key_of_documentid, tf_d|
		# 			# tf_document_normalize (BM25)
		# 			tf_d_n = tf_d / (0.25 + 0.75 * $doclen[key_of_documentid] / $avgdoclen)
		# 			# TF-IDF
		# 			w_d = tf_d_n * idf
		# 			scores[key_of_documentid] += w_d * w_q * alpha
		# 			# length_d[key_of_documentid] += w_d ** 2
		# 			# length_q[key_of_documentid] += w_q ** 2
		# 		end
		# 	end		
		# else # if query_term.count == 2
		# 	query_term = "#{query_term[0]}_#{query_term[1]}"
		# 	#### caculate scores
		# 	if $dictionary.has_key?(query_term)
		# 		df  = $dictionary[query_term]
		# 		idf = Math.log10(corpus_size/df) # df
		# 		# TF-IDF of query
		# 		w_q = tf_q * idf
		# 		posting_list = eval(File.open("./model-files/inverted-index_hash/#{query_term}", "rb").read)
		# 		posting_list.each do |key_of_documentid, tf_d|
		# 			# tf_document_normalize (BM25)
		# 			tf_d_n = tf_d / (0.25 + 0.75 * $doclen[key_of_documentid] / $avgdoclen)
		# 			# TF-IDF
		# 			w_d = tf_d_n * idf
		# 			scores[key_of_documentid] += w_d * w_q * beta
		# 			# length_d[key_of_documentid] += w_d ** 2
		# 			# length_q[key_of_documentid] += w_q ** 2
		# 		end
		# 	end			
		# end

		# process query term	
		query_term = "#{query_term[0]}_#{query_term[1]}"
		#### caculate scores
		if $dictionary.has_key?(query_term)
			idf = Math.log10(97445/$dictionary[query_term]) # df
			# TF-IDF of query
			f = File.open("#{$options[:m]}/inverted-index_converted/#{query_term}", "rb")
			posting_list = eval(f.read)
			posting_list.each do |key_of_documentid, tf_d|
				# tf_document_normalize (BM25) -> TF-IDF
				scores[key_of_documentid] += tf_d / (0.25 + 0.75 * $doclen[key_of_documentid] / $avgdoclen) * idf
			end
			f.close
		end			
	end	 
	### find top K
	# relevent = Array.new
	# sort hash, rank score, small -> big
	# scores.each do |key_of_documentid, score|
	# 	# scores[key_of_documentid] = score / Math.sqrt(length_d[key_of_documentid] * length_q[key_of_documentid])
	# 	scores[key_of_documentid] = score
	# 	# scores[key_of_documentid] = score
	# 	# if scores[key_of_documentid] > threshold
	# 		# relevent << key_of_documentid
	# 	# end
	# end
	# puts scores.values.sort
	return scores # key_of_documentid
end

### query parser, input query-5 or query-30 file, n, output ngram.all (file in disk)
def ParseQuery(n)
	require "rexml/document"
	include REXML
	query_file = REXML::Document.new(File.open($options[:i], "r"))
	Dir.mkdir("#{$dir_queryfile}/queries_converted")

	query_number = 1 #to name file_name
	query_file.elements.each("xml/topic") do |topic|
		# parse query
		file_name = "query#{query_number}"
		puts "Parse #{file_name}..."
		query_f = File.open("#{$dir_queryfile}/queries_converted/#{file_name}.xml", 'w')
		query_f.write(topic)
		query_f.close()

		# create ngram
		case n
		when 1 # unigram only
			%x( src/bin/create-ngram -vocab src/data/vocab.all -o #{$dir_queryfile}/queries_converted/#{file_name}_ngram.all -n 1 -encoding utf8 #{$dir_queryfile}/queries_converted/#{file_name}.xml )
		when 2 # bigram only
			%x( src/bin/create-ngram -vocab src/data/vocab.all -o #{$dir_queryfile}/queries_converted/#{file_name}_ngram.all -n 2 -encoding utf8 #{$dir_queryfile}/queries_converted/#{file_name}.xml )
		when 3 # unigram + bigram  merge
			%x( src/bin/create-ngram -vocab src/data/vocab.all -o #{$dir_queryfile}/queries_converted/unigram.temp -n 1 -encoding utf8 #{$dir_queryfile}/queries_converted/#{file_name}.xml )
			%x( src/bin/create-ngram -vocab src/data/vocab.all -o #{$dir_queryfile}/queries_converted/bigram.temp  -n 2 -encoding utf8 #{$dir_queryfile}/queries_converted/#{file_name}.xml )
			%x( src/bin/merge-ngram -o #{$dir_queryfile}/queries_converted/#{file_name}_ngram.all #{$dir_queryfile}/queries_converted/unigram.temp #{$dir_queryfile}/queries_converted/bigram.temp )
		end
		query_number += 1
	end
end

def PickTopK (scores, topK) 
	# sort hash, rank score, small -> big                            # get top K as revelent                
	return Hash[ scores.sort_by {|key_of_documentid, score| score }].keys[-topK..-1].reverse!  
end

### Rocchio Relevance Feedback (pseudo version), input relevent array, fetch topK, output top K relevent array
def Rocchio(queryi, scores, scores_topk, topK)
	# queryi_ngram_all = File.open("./queries/query#{queryi}_ngram.all", "r").readlines
	File.new("#{$dir_queryfile}/queries_converted//query#{queryi}_R_ngram.all", "w")
	(0..topK-1).each do |k|
		file_name = $file_list[scores_topk[k]].strip
		file_name = "#{$options[:d]}/.#{file_name}"  
		# %x( src/bin/create-ngram -vocab src/data/vocab.all -o queries/unigram.temp -n 1 -encoding utf8 #{file_name} )
		%x( src/bin/create-ngram -vocab src/data/vocab.all -o #{$dir_queryfile}/queries_converted/bigram.temp  -n 2 -encoding utf8 #{file_name} )
		%x( src/bin/merge-ngram -o #{$dir_queryfile}/queries_converted/query#{queryi}_R_ngram.all #{$dir_queryfile}/queries_converted/query#{queryi}_R_ngram.all #{$dir_queryfile}/queries_converted/bigram.temp )
	end
	FastCosineScore("#{queryi}_R") # return Scores Hash
end