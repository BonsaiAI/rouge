# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class Inkling < RegexLexer
      title "Inkling"
      desc "Inkling Brain Definition Language"

      tag 'inkling2'
      aliases 'ink'
      filenames '*.ink', '*.inkling'
      mimetypes 'application/ink', 'application/inkling'

      state :comments_and_whitespace do
        rule /\s+/, Text
        rule %r(#.*?$), Comment::Single
      end

      state :expr_start do
        mixin :comments_and_whitespace

        rule %r(/) do
          token Str::Regex
          goto :regex
        end

        rule /[{]/ do
          token Punctuation
          goto :object
        end

        rule //, Text, :pop!
      end

      state :regex do
        rule %r(/) do
          token Str::Regex
          goto :regex_end
        end

        rule %r([^/]\n), Error, :pop!

        rule /\n/, Error, :pop!
        rule /\[\^/, Str::Escape, :regex_group
        rule /\[/, Str::Escape, :regex_group
        rule /\\./, Str::Escape
        rule %r{[(][?][:=<!]}, Str::Escape
        rule /[{][\d,]+[}]/, Str::Escape
        rule /[()?]/, Str::Escape
        rule /./, Str::Regex
      end

      state :regex_end do
        rule /[gim]+/, Str::Regex, :pop!
        rule(//) { pop! }
      end

      state :regex_group do
        # specially highlight / in a group to indicate that it doesnt
        # close the regex
        rule /\//, Str::Escape

        rule %r([^/]\n) do
          token Error
          pop! 2
        end

        rule /\]/, Str::Escape, :pop!
        rule /\\./, Str::Escape
        rule /./, Str::Regex
      end

      state :bad_regex do
        rule /[^\n]+/, Error, :pop!
      end

      def self.keywords
        @keywords ||= Set.new %w(
        action algorithm and concept config const constraint curriculum else
        experiment function graph if inkling input lesson not or output package
        return reward simulator source state step terminal threshold type
        using var number string false true
        )
      end

      def self.id_regex
        /[$a-z_][a-z0-9_]*/io
      end

      id = self.id_regex

      state :root do
        rule /\A\s*#!.*?\n/m, Comment::Preproc, :statement
        rule %r((?<=\n)(?=\s|/|<!--)), Text, :expr_start
        mixin :comments_and_whitespace
        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | ===
               | !== )x,
          Operator, :expr_start
        rule %r([-<>+*%&|\^/!=]=?), Operator, :expr_start
        rule /[(\[,]/, Punctuation, :expr_start
        rule /;/, Punctuation, :statement
        rule /[)\].]/, Punctuation
        rule /[']/, Punctuation

        rule /`/ do
          token Str::Double
          push :template_string
        end

        rule /[?]/ do
          token Punctuation
          push :ternary
          push :expr_start
        end

        rule /(\@)(\w+)?/ do
          groups Punctuation, Name::Decorator
          push :expr_start
        end

        rule /[{}]/, Punctuation, :statement

        rule id do |m|
          if self.class.keywords.include? m[0]
            token Keyword
            push :expr_start
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
            push :expr_start
          elsif self.class.reserved.include? m[0]
            token Keyword::Reserved
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end
        end

        rule /[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/, Num::Float
        rule /0x[0-9a-fA-F]+/, Num::Hex
        rule /[0-9]+/, Num::Integer
        rule /"(\\[\\"]|[^"])*"/, Str::Double
        # rule /(\\[\\]|[^])*/, Str::Single
        rule /:/, Punctuation
      end

      # braced parts that arent object literals
      state :statement do
        rule /case\b/ do
          token Keyword
          goto :expr_start
        end

        rule /(#{id})(\s*)(:)/ do
          groups Name::Label, Text, Punctuation
        end

        rule /[{}]/, Punctuation

        mixin :expr_start
      end

      # object literals
      state :object do
        mixin :comments_and_whitespace

        rule /[{]/ do
          token Punctuation
          push
        end

        rule /[}]/ do
          token Punctuation
          goto :statement
        end

        rule /(#{id})(\s*)(:)/ do
          groups Name::Attribute, Text, Punctuation
          push :expr_start
        end

        rule /:/, Punctuation
        mixin :root
      end

      # ternary expressions, where <id>: is not a label!
      state :ternary do
        rule /:/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end

      # template strings
      state :template_string do
        rule /\${/, Punctuation, :template_string_expr
        rule /`/, Str::Double, :pop!
        rule /(\\\\|\\[\$`]|[^\$`]|\$(?!{))*/, Str::Double
      end

      state :template_string_expr do
        rule /}/, Punctuation, :pop!
        mixin :root
      end
    end
  end
end
