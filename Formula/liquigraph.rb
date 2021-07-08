class Liquigraph < Formula
  desc "Migration runner for Neo4j"
  homepage "https://www.liquigraph.org/"
  url "https://github.com/liquigraph/liquigraph/archive/liquigraph-4.0.3.tar.gz"
  sha256 "748ceb4dee52df1edca73570f0ab081ebac2fe93c9c223ea71fa34cbc76553fc"
  license "Apache-2.0"
  head "https://github.com/liquigraph/liquigraph.git"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "bf45c4112732a17a867a17a18cc1ad77d71dbebfdca84f00843bd9526c4d6ed2"
    sha256 cellar: :any_skip_relocation, big_sur:       "1fa0da0d2e5c22f63faed17097c320d4a639c4d3855385f541cf948aa6a5a61b"
    sha256 cellar: :any_skip_relocation, catalina:      "33d7c1bae094524db782c9b3d3b0f37b4353f772529ab143b456c6271e262059"
    sha256 cellar: :any_skip_relocation, mojave:        "3a6ed6c8c176e1ffa0e3faef3cd1ed0025663dc23fd2d839372a9766e26fd2b7"
    sha256 cellar: :any_skip_relocation, high_sierra:   "d8c4ae157ed9d5ea8aad53d9b07784c21e41a4ac5a7756f0dacb9f526e809405"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "18bdc64b095feea09c0a07c951ca6adbe03611794f39f2b03367775a210c0591"
  end

  depends_on "maven" => :build
  depends_on "openjdk@11"

  def install
    ENV["JAVA_HOME"] = Formula["openjdk@11"].opt_prefix
    system "mvn", "-B", "-q", "-am", "-pl", "liquigraph-cli", "clean", "package", "-DskipTests"
    (buildpath/"binaries").mkpath
    system "tar", "xzf", "liquigraph-cli/target/liquigraph-cli-bin.tar.gz", "-C", "binaries"
    libexec.install "binaries/liquigraph-cli/liquigraph.sh"
    libexec.install "binaries/liquigraph-cli/liquigraph-cli.jar"
    (bin/"liquigraph").write_env_script libexec/"liquigraph.sh", JAVA_HOME: "${JAVA_HOME:-#{ENV["JAVA_HOME"]}}"
  end

  test do
    failing_hostname = "verrryyyy_unlikely_host"
    changelog = testpath/"changelog"
    changelog.write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <changelog>
          <changeset id="hello-world" author="you">
              <query>CREATE (n:Sentence {text:'Hello monde!'}) RETURN n</query>
          </changeset>
          <changeset id="hello-world-fixed" author="you">
              <query>MATCH (n:Sentence {text:'Hello monde!'}) SET n.text='Hello world!' RETURN n</query>
          </changeset>
      </changelog>
    EOS

    jdbc = "jdbc:neo4j:http://#{failing_hostname}:7474/"
    output = shell_output("#{bin}/liquigraph "\
                          "dry-run -d #{testpath} "\
                          "--changelog #{changelog.realpath} "\
                          "--graph-db-uri #{jdbc} 2>&1", 1)
    assert_match "Exception: #{failing_hostname}", output
  end
end
