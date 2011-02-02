module ORS::Commands

  class Base

    include ORS::Utils

    module ClassMethods
      def run klass
        klass.new.execute
      end
    end
    extend ClassMethods

    def run klass
      self.class.run klass
    end

  end

end
