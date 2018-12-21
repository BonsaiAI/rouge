# -*- coding: utf-8 -*- #

describe Rouge::Lexers::Inkling do
  let(:subject) { Rouge::Lexers::Inkling.new }

  describe 'guessing' do
    include Support::Guessing

    it 'guesses by filename' do
      assert_guess :filename => 'foo.ink'
      assert_guess :filename => 'foo.ink2'
      assert_guess :filename => 'foo.inkling'
    end

    it 'guesses by mimetype' do
      assert_guess :mimetype => 'text/ink'
      assert_guess :mimetype => 'text/ink2'
      assert_guess :mimetype => 'application/ink'
      assert_guess :mimetype => 'application/ink2'
    end

    it 'guesses by source' do
      assert_guess :source => '<xml></xml>'
      assert_guess :source => '<?xml version="1.0" encoding="utf-8"?>'
      assert_guess :source => '<!DOCTYPE xml>'
      deny_guess   :source => '<!DOCTYPE html>'
    end
  end
end
