require 'fileutils'

describe Workflows::Page do
  subject { described_class.new(path: nil) }
  let(:fixture_path) { Pathname.new(File.expand_path(File.join(__FILE__, '..', '..', 'fixtures', fixture_name))) }
  before { subject.process }

  around do |example|
    Dir.mktmpdir do |dir|
      tmp_fixture_path = Pathname.new(dir).join(fixture_path.basename)
      FileUtils.cp fixture_path, tmp_fixture_path
      subject.path = tmp_fixture_path
      example.run
    end
  end

  context 'empty pages' do
    let(:fixture_name) { 'empty.tiff' }

    it 'detects and deletes them' do
      expect(subject.empty?).to be true
      expect(File.exist?(subject.pdf_path)).to be false
    end
  end

  context 'non-empty pages' do
    let(:fixture_name) { 'basic.tiff' }

    it 'detects and keeps them' do
      expect(subject.empty?).to be false
      expect(File.exist?(subject.pdf_path)).to be true
    end
  end
end
