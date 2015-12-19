class SmaliField
    attr_reader :name, :class, :type, :descriptor

    def initialize(class_name, field_signature)
        @class = class_name
        @descriptor = "#{class_name}->#{field_signature}"
        @name, @type = field_signature.split(':')
    end

    def to_s
        @descriptor
    end

    def ==(other)
        other.class == self.class && other.state == state
    end

    def state
        [@name, @class, @type, @descriptor]
    end
end
