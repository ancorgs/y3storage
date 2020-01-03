module Y2Storage
  module AutoinstIssues
    # Base class for storage-ng autoinstallation problems.
    #
    # Y2Storage::AutoinstIssues offers an API to register and report storage
    # related AutoYaST problems.
    class Issue
      # @return [#parent,#section_name] Section where it was detected (see {AutoinstProfile})
      attr_reader :section

      # Return problem severity
      #
      # * :fatal: abort the installation.
      # * :warn:  display a warning.
      #
      # @return [Symbol] Issue severity (:warn, :fatal)
      # @raise NotImplementedError
      def severity
        raise NotImplementedError
      end

      # Return the error message to be displayed
      #
      # @return [String] Error message
      # @raise NotImplementedError
      def message
        raise NotImplementedError
      end

      # Determine whether an error is fatal
      #
      # This is just a convenience method.
      #
      # @return [Boolean]
      def fatal?
        severity == :fatal
      end

      # Determine whether an error is just a warning
      #
      # This is just a convenience method.
      #
      # @return [Boolean]
      def warn?
        severity == :warn
      end
    end
  end
end
