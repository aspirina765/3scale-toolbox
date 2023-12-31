module ThreeScaleToolbox
  module Commands
    module ThreeScaleCommand
      include ThreeScaleToolbox::Command

      def self.command
        Cri::Command.define do
          name        '3scale'
          usage       '3scale <sub-command> [options]'
          summary     '3scale toolbox'
          description '3scale toolbox to manage your API from the terminal.'
          option :c, 'config-file', '3scale toolbox configuration file',
                 argument: :required, default: ThreeScaleToolbox.default_config_file
          flag :v, :version, 'Prints the version of this command' do
            puts ThreeScaleToolbox::VERSION
            exit 0
          end
          flag :k, :insecure, 'Proceed and operate even for server connections otherwise considered insecure'
          flag nil, :verbose, 'Verbose mode'
          flag nil, :'disable-keep-alive', 'Disable keep alive HTTP connection mode'
          flag :h, :help, 'show help for this command' do |_, cmd|
            puts cmd.help
            exit 0
          end

          run do |_opts, _args, cmd|
            puts cmd.help
          end
        end
      end
    end
  end
end
