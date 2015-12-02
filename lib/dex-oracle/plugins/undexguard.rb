require_relative '../logging'

class Undexguard < Plugin
  include Logging
  include CommonRegex

  STRING_LOOKUP_3INT = Regexp.new(
      '^[ \t]*(' <<
          ((CONST_NUMBER << '\s+') * 3) <<
          'invoke-static \{[vp]\d+, [vp]\d+, [vp]\d+\}, L([^;]+);->([^\(]+\(III\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')', Regexp::MULTILINE)

  STRING_LOOKUP_1INT = Regexp.new(
      '^[ \t]*(' <<
          CONST_NUMBER << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(I\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(Ljava/lang/String;\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT_ALT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'new-instance ([vp]\d+), L[^;]+;\s+' <<
          '(?:move-object(?:\/from16)? [vp]\d+, [vp]\d+\s+)?' <<
          'invoke-static {.+?\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual {[vp]\d+}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\/String;\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-direct {.+?\(\[B\)V' <<
          ')')

  def self.process(driver, smali_files)
    method_to_batch_info = {}
    smali_files.each do |smali_file|
      smali_file.methods.each do |method|
        #next unless method.descriptor =~ %r|Lcom/android/system/admin/ICcIIlo;->test|

        logger.debug("Undexguarding #{method.descriptor}")
        batch_info = {}
        batch_info.merge!(Undexguard.lookup_strings_3int(driver, method))
        batch_info.merge!(Undexguard.lookup_strings_1int(driver, method))
        batch_info.merge!(Undexguard.decrypt_strings(driver, method))
        batch_info.map { |k, v| v.uniq! }
        method_to_batch_info[method] = batch_info unless batch_info.empty?
      end
    end

    Undexguard.apply_batch(driver, method_to_batch_info)
  end

  private

  def self.apply_batch(driver, method_to_batch_info)
    all_batches = method_to_batch_info.values.collect { |e| e.keys }.flatten
    outputs = driver.run_batch(all_batches)

    made_changes = false
    method_to_batch_info.each do |method, batch_info|
      batch_info.each do |item, infos|
        status, output = outputs[item[:id]]
        unless status == 'success'
          logger.warn(output)
          next
        end

        infos.each do |original, out_reg|
          modification = "const-string #{out_reg}, #{output}"
          #puts "modification #{original.inspect} = #{modification.inspect}"
          # Go home Ruby, you're drunk.
          modification.gsub!('\\') { '\\\\' }
          method.body.gsub!(original) { modification }
        end

        made_changes = true
        method.modified = true
      end
    end

    made_changes
  end

  def self.lookup_strings_3int(driver, method)
    batch_info = {}
    matches = method.body.scan(STRING_LOOKUP_3INT)
    matches.each do |original, arg1, arg2, arg3, class_name, method_signature, out_reg|
      item = driver.make_batch_item(
        class_name, method_signature, arg1.to_i(16), arg2.to_i(16), arg3.to_i(16)
      )
      batch_info[item] = [] unless batch_info.has_key?(item)
      batch_info[item] << [original, out_reg]
    end

    batch_info
  end

  def self.lookup_strings_1int(driver, method)
    batch_info = {}
    matches = method.body.scan(STRING_LOOKUP_1INT)
    matches.each do |original, arg1, class_name, method_signature, out_reg|
      item = driver.make_batch_item(
        class_name, method_signature, arg1.to_i(16)
      )
      batch_info[item] = [] unless batch_info.has_key?(item)
      batch_info[item] << [original, out_reg]
    end

    batch_info
  end

  def self.decrypt_strings(driver, method)
    batch_info = {}
    matches = method.body.scan(STRING_DECRYPT)
    matches.each do |original, encrypted, class_name, method_signature, out_reg|
      item = driver.make_batch_item(
        class_name, method_signature, encrypted
      )
      batch_info[item] = [] unless batch_info.has_key?(item)
      batch_info[item] << [original, out_reg]
    end

    batch_info
  end
end
