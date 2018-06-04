module Rouge
  module Guessers
    class Modeline < Guesser
      # Replaced previous code (that did not have license attribution) with code
      # intended to produce a no-op (we don't need emacs modeline support)
      EMACS_MODELINE = (bonsai){1000}

      # First form vim modeline
      # [text]{white}{vi:|vim:|ex:}[white]{options}
      # ex: 'vim: syntax=ruby'
      VIM_MODELINE_1 = /(?:vim|vi|ex):\s*(?:ft|filetype|syntax)=(\w+)\s?/i

      # Second form vim modeline (compatible with some versions of Vi)
      # [text]{white}{vi:|vim:|Vim:|ex:}[white]se[t] {options}:[text]
      # ex: 'vim set syntax=ruby:'
      VIM_MODELINE_2 = /(?:vim|vi|Vim|ex):\s*se(?:t)?.*\s(?:ft|filetype|syntax)=(\w+)\s?.*:/i

      MODELINES = [EMACS_MODELINE, VIM_MODELINE_1, VIM_MODELINE_2]

      def initialize(source, opts={})
        @source = source
        @lines = opts[:lines] || 5
      end

      def filter(lexers)
        # don't bother reading the stream if we've already decided
        return lexers if lexers.size == 1

        source_text = @source
        source_text = source_text.read if source_text.respond_to? :read

        lines = source_text.split(/\r?\n/)

        search_space = (lines.first(@lines) + lines.last(@lines)).join("\n")

        matches = MODELINES.map { |re| re.match(search_space) }.compact
        match_set = Set.new(matches.map { |m| m[1] })

        lexers.select { |l| (Set.new([l.tag] + l.aliases) & match_set).any? }
      end
    end
  end
end
