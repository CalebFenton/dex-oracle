require 'digest'
require_relative '../logging'

class Unreflector < Plugin
  include Logging
  include CommonRegex

  CLASS_FOR_NAME = 'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;'

  CONST_CLASS_REGEX = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  VIRTUAL_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STATIC_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          CONST_STRING <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          'const/4 [vp]\d+, 0x0\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  def self.process(driver, smali_files, methods)
    made_changes = false
    methods.each do |method|
      logger.info("Unreflecting #{method.descriptor}")
      made_changes |= Unreflector.lookup_classes(driver, method)
    end

    made_changes
  end

  private

  def self.lookup_classes(driver, method)
    target_to_contexts = {}
    target_id_to_output = {}
    matches = method.body.scan(CONST_CLASS_REGEX)
    matches.each do |original, class_name, out_reg|
      target = { id: Digest::SHA256.hexdigest(original) }
      smali_class = "L#{class_name.gsub('.', '/')};"
      target_id_to_output[target[:id]] = ['success', smali_class]
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    method_to_target_to_contexts = { method => target_to_contexts }
    modifier = lambda { |original, output, out_reg| "const-class #{out_reg}, #{output}" }
    Plugin.apply_outputs(target_id_to_output, method_to_target_to_contexts, modifier)
  end
end
