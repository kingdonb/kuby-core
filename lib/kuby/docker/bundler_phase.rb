# typed: strict

require 'pathname'

module Kuby
  module Docker
    class BundlerPhase < Layer
      extend T::Sig

      DEFAULT_WITHOUT = T.let(
        ['development', 'test', 'deploy'].freeze, T::Array[String]
      )

      sig { returns(T.nilable(String)) }
      attr_reader :version

      sig { params(version: String).void }
      attr_writer :version

      sig { returns(T.nilable(String)) }
      attr_reader :gemfile

      sig { params(gemfile: String).void }
      attr_writer :gemfile

      sig { returns(T.nilable(T::Array[String])) }
      attr_reader :without

      sig { params(without: T::Array[String]).void }
      attr_writer :without

      sig { returns(T.nilable(String)) }
      attr_reader :executable

      sig { params(executable: String).void }
      attr_writer :executable

      sig { params(environment: Environment).void }
      def initialize(environment)
        super

        @version = T.let(@version, T.nilable(String))
        @gemfile = T.let(@gemfile, T.nilable(String))
        @gemfiles = T.let([], T::Array[String])
        @without = T.let(@without, T.nilable(T::Array[String]))
        @executable = T.let(@executable, T.nilable(String))
      end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        gf = gemfile || default_gemfile
        lf = "#{gf}.lock"
        v = version || default_version
        wo = without || DEFAULT_WITHOUT

        dockerfile.run('gem', 'install', 'bundler', '-v', v)

        # bundle install
        dockerfile.copy(gf, '.')
        dockerfile.copy(lf, '.')

        @gemfiles.each do |file|
          dockerfile.copy(file, file)
        end

        unless wo.empty?
          dockerfile.env("BUNDLE_WITHOUT='#{wo.join(' ')}'")
        end

        dockerfile.arg("MINIO_ACCESS_KEY=required")
        dockerfile.arg("MINIO_SECRET_KEY=required")
        dockerfile.env("MINIO_ACCESS_KEY ${MINIO_ACCESS_KEY}")
        dockerfile.env("MINIO_SECRET_KEY ${MINIO_SECRET_KEY}")

        dockerfile.run(
          executable || 'bundle', 'install',
          '--jobs', '$(nproc)',
          '--retry', '3',
          '--gemfile', gf
        )

        #   %w'gem install specific_install')
        # dockerfile.run(
        #   %w'gem specific_install https://github.com/kingdonb/prebundler')
        # dockerfile.copy('.prebundle_config', '.')
        # dockerfile.run(
        #   %w'prebundle install')

        # generate binstubs and add the bin directory to our path
        dockerfile.run(executable || 'bundle', 'binstubs', '--all')
        # dockerfile.run(executable || 'bundle', 'binstubs', '--all')
        #>>>>>>> 6a77b29 (don't run bundle binstubs --all)
        dockerfile.env("PATH=./bin:$PATH")
      end

      sig { params(paths: String).void }
      def gemfiles(*paths)
        @gemfiles.concat(paths)
      end

      private

      sig { returns(String) }
      def default_version
        Bundler::VERSION
      end

      sig { returns(String) }
      def default_gemfile
        Bundler
          .definition
          .gemfiles
          .first
          .relative_path_from(Pathname(Dir.getwd))
          .to_s
      end
    end
  end
end
