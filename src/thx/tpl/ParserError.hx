/**
 * @author Waneck
 * @author Franco Ponticelli
 */

package thx.tpl;

import haxe.PosInfos;
import thx.Error;
import haxe.CallStack;

class ParserError extends Error {
  public var excerpt(default, null) : String;

  public function new(message : String, ?excerpt : String, ?stack : Array<StackItem>, ?pos : PosInfos) {
    super(message, stack, pos);
    this.excerpt = excerpt;
  }

  override public function toString() {
    var excerpt = this.excerpt;
    if (excerpt != null) {
      var nl = excerpt.indexOf("\n");
      if (nl > 0)
        excerpt = excerpt.substr(0, nl);
      excerpt = '\nat:\n$excerpt';
    } else {
      excerpt = '';
    }
    return super.toString() + excerpt;
  }
}