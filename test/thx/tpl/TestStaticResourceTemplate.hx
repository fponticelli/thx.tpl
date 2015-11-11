package thx.tpl;

import utest.Assert;
import thx.tpl.HtmlTemplate;

class TestStaticResourceTemplate {
  public function new() {}

  public function testStaticResource() {
    var template = new HtmlTemplate(Resource.sample);
    var output = template.execute(["title" => "Page Title", "content" => "Page Content"]);
    Assert.stringContains("<title>Page Title</title>", output);
    Assert.stringContains("<div>Page Content</div>", output);
  }
}

@:dir("test/templates")
class Resource implements thx.StaticResource {}
