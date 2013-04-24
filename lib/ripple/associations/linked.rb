require 'ripple/associations'
require 'set'

module Ripple
  module Associations
    module Linked
      def replace(value)
        @reflection.verify_type!(value, @owner)
        @owner.robject.links -= links
        Array.wrap(value).compact.each do |doc|
          @owner.robject.links << doc.to_link(@reflection.link_tag)
        end
        loaded
        @keys = nil
        @target = value
      end

      def replace_links(value)
        @owner.robject.links -= links
        Array(value).each do |link|
          @owner.robject.links << link
        end
        reset
      end

      def keys
        @keys ||= Set.new(links.map { |l| l.key })
      end

      def reset
        super
        @keys = nil
      end

      def include?(document)
        return false unless document.respond_to?(:robject)

        # TODO: when we allow polymorphic assocations, this will have to change
        #       since @reflection.bucket_name will be '_' in that case.
        return false unless document.robject.bucket.name == @reflection.bucket_name
        keys.include?(document.key)
      end

      protected
      def links
        @owner.robject.links.select(&@reflection.link_filter)
      end

      def client
        client = @owner.robject.bucket.client
      end

      def robjects
        links.map do |link|
          bucket = client.bucket(link.bucket)
          bucket.get(link.key)
        end
      end
    end
  end
end
