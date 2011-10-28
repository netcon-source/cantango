module CanTango
  class Configuration
    class Permits < PermitRegistry
      include Singleton

      attr_reader :accounts
      attr_writer :enabled_types

      def enabled_types
        @enabled_types || available_types
      end
      alias_method :enabled, :enabled_types

      def available_types
        [:user, :account, :role, :role_group, :special]
      end

      def disable_types *types
        @enabled_types = available_types - types.flatten
      end
      alias_method :disable, :disable_types

      def enable_all_types!
        @enabled_types = available_types
      end

      def disable_for type, *names
        @disabled ||= {}
        @disabled[type.to_sym] = names.flatten.select_labels.map{|n| n.to_s.underscore}
      end

      def enable_all_for type
        @disabled ||= {}
        @disabled[type.to_sym] = nil
      end

      def disabled
        @disabled ||= {}
      end

      def disabled_for type
        disabled[type]
      end

      def enable_all!
        @disabled = {}
        enable_all_types!
      end

      def accounts
        @accounts ||= Hash.new
      end

      def account_hash name
        accounts[name]
      end

      def method_missing method_name, *args
        accounts[method_name] ||= PermitRegistry.new
      end

      def register_permit_class(permit_name, permit_clazz, permit_type, account_name)
        registry = account_name ? self.send(account_name.to_sym) : self
        puts "Registering #{permit_type} permit: #{permit_name} of class #{permit_clazz}" if CanTango.debug?
        registry.send(permit_type)[permit_name] = permit_clazz
        puts registry.send(permit_type).inspect if CanTango.debug?
      end

      def allowed candidate, actions, subjects, *extra_args
        executed_for(candidate).inject([]) do |result, permit|
          result << permit.class if permit.can? actions, subjects, *extra_args
          result
        end
      end

      def denied candidate, actions, subjects, *extra_args
        executed_for(candidate).inject([]) do |result, permit|
          result << permit.class if permit.cannot? actions, subjects, *extra_args
          result
        end
      end

      def was_executed permit, ability
        executed_for(ability) << permit
      end

      def executed_for ability
        executed[hash_key_for(ability)] ||= []
      end

      def executed
        @executed ||= {}
      end

      def clear_executed!
        @executed = nil
      end

      protected

      def hash_key_for subject
        key_for(subject).value
      end

      def key_for subject
        subject.kind_of?(CanTango::Ability) ? key_maker.create_for(subject) : key_maker.new(subject)
      end

      def key_maker
        CanTango::Ability::Cache::Key
      end
    end
  end
end


