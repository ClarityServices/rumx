module Rumx
  # Defines a Rumx bean that allows access to the defined attributes and operations.
  # All public instance methods are prefixed with "bean_" to try to avoid collisions.
  module Bean
    module ClassMethods

      def bean_reader(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, true, false))
      end

      def bean_attr_reader(name, type, description)
        attr_reader(name)
        bean_reader(name, type, description)
      end

      def bean_writer(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, false, true))
      end

      def bean_attr_writer(name, type, description)
        attr_writer(name)
        bean_writer(name, type, description)
      end

      def bean_accessor(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, true, true))
      end

      def bean_attr_accessor(name, type, description)
        attr_accessor(name)
        bean_accessor(name, type, description)
      end

      def bean_add_attribute(attribute)
        @attributes ||= []
        @attributes << attribute
      end

      def bean_attributes
        attributes = []
        self.ancestors.reverse_each do |mod|
          attributes += mod.bean_attributes_local if mod.include?(Rumx::Bean)
        end
        return attributes
      end

      #bean_operation     :my_operation,       :string,  'My operation', [
      #    [ :arg_int,    :int,    'An int argument'   ],
      #    [ :arg_float,  :float,  'A float argument'  ],
      #    [ :arg_string, :string, 'A string argument' ]
      #]
      def bean_operation(name, type, description, args)
        arguments = args.map do |arg|
          raise 'Invalid bean_operation format' unless arg.kind_of?(Array) && arg.size == 3
          Argument.new(*arg)
        end
        @operations ||= []
        @operations << Operation.new(name, type, description, arguments)
      end

      def bean_operations
        operations = []
        self.ancestors.reverse_each do |mod|
          operations += mod.bean_operations_local if mod.include?(Rumx::Bean)
        end
        return operations
      end

      def bean_attributes_local
        @attributes ||= []
      end

      def bean_operations_local
        @operations ||= []
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.root
      @root ||= FolderBean.new
    end

    def self.find(name_array)
      bean = root
      name_array.each do |name|
        bean = bean.bean_children[name]
        return nil unless bean
      end
      bean
    end

    # Return [bean, attribute] pair or nil if not found
    def self.find_attribute(name_array)
      attr_name = name_array.pop
      bean = Bean.find(name_array)
      return nil unless bean
      attribute = bean.bean_find_attribute(attr_name)
      return nil unless attribute
      return [bean, attribute]
    end

    # Return [bean, operation] pair or nil if not found
    def self.find_operation(name_array)
      oper_name = name_array.pop
      bean = Bean.find(name_array)
      return nil unless bean
      operation = bean.bean_find_operation(oper_name)
      return nil unless operation
      return [bean, operation]
    end

    # Mutex for synchronization of attributes/operations
    def bean_mutex
      # TBD: How to initialize this in a module and avoid race condition?
      @mutex || Mutex.new
    end

    # Synchronize access to attributes and operations
    def bean_synchronize
      bean_mutex.synchronize do
        yield
      end
    end

    def bean_children
      @bean_children ||= {}
    end

    def bean_add_child(name, child_bean)
      # TBD - Should I mutex protect this?  All beans would normally be registered during the code initialization process
      raise "Error trying to add #{name} to embedded bean" if @bean_is_embedded
      bean_children[name.to_s] = child_bean
    end

    def bean_remove_child(name)
      bean_children.delete(name.to_s)
    end

    def bean_embedded_children
      @bean_embedded_children ||= {}
    end

    def bean_add_embedded_child(name, embedded_child_bean)
      raise "Error trying to add bean #{name} as embedded, it already has children" unless embedded_child_bean.bean_children.empty?
      embedded_child_bean.instance_variable_set('@bean_is_embedded', true)
      bean_embedded_children[name.to_s] = embedded_child_bean
    end

    def bean_remove_embedded_child(name)
      bean_embedded_children.delete(name.to_s)
    end

    def bean_find_attribute(name)
      name = name.to_sym
      self.class.bean_attributes.each do |attribute|
        return attribute if name == attribute.name
      end
      return nil
    end

    def bean_find_operation(name)
      name = name.to_sym
      self.class.bean_operations.each do |operation|
        return operation if name == operation.name
      end
      return nil
    end

    def bean_find_embedded(name)
      name = name.to_s
      @bean_embedded_children.each do |bean_name, bean|
        return bean if bean_name == name
      end
      return nil
    end

    def bean_get_attributes
      bean_synchronize do
        do_bean_get_attributes
      end
    end

    def bean_set_attributes(params)
      bean_synchronize do
        do_bean_set_attributes(params)
      end
    end

    def bean_get_and_set_attributes(params)
      hash = nil
      bean_synchronize do
        hash = do_bean_get_attributes
        do_bean_set_attributes(params)
      end
      hash
    end

    def bean_set_and_get_attributes(params)
      hash = nil
      bean_synchronize do
        do_bean_set_attributes(params)
        hash = do_bean_get_attributes
      end
      hash
    end

    #########
    protected
    #########

    # Allow extenders to save changes, etc. if attribute values change
    def bean_attributes_changed
    end

    #######
    private
    #######

    # Separate call in case we're already mutex locked
    def do_bean_get_attributes
      hash = {}
      self.class.bean_attributes.each do |attribute|
        hash[attribute] = attribute.get_value(self)
      end
      bean_embedded_children.each do |name, bean|
        hash[name] = bean.bean_get_attributes
      end
      hash
    end

    # Separate call in case we're already mutex locked
    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      self.class.bean_attributes.each do |attribute|
        if attribute.allow_write
          if params.has_key?(attribute.name)
            attribute.set_value(self, params[attribute.name])
            changed = true
          elsif params.has_key?(attribute.name.to_s)
            attribute.set_value(self, params[attribute.name.to_s])
            changed = true
          end
        end
      end
      bean_embedded_children.each do |name, bean|
        embedded_params = params[name]
        bean.bean_set_attributes(embedded_params)
      end
      bean_attributes_changed if changed
    end
  end
end
