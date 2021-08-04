import Types "../Types";
import Hash "mo:base/Hash";

/// Terminal-related abstractions.
module {

  public type Dim = Types.Dim;
  public type Elm = Types.Graphics.Elm;
  public type EventInfo = Types.Event.EventInfo;

  /// Simple "core behavior" of an icmt-based service.
  public type Core = object {
    clone : () -> Core;
    draw : Dim -> Elm;
    update : EventInfo -> ();
  };

  /// Like Core, but permits indexing and caching based on hashes.
  public type Cached<X> = object {
    equal : X -> Bool;
    hash : Hash.Hash;
    clone : () -> Cached<X>;
    draw : Dim -> Elm;
    update : EventInfo -> ();
  };

  public type Terminal = object {
    view : (Types.Dim, [EventInfo]) -> ViewResult;
    update : ([EventInfo], GfxReq) -> UpdateResult;
  };

  public type GfxReq = Types.GraphicsRequest;
  public type ViewResult = Types.Graphics.Result;
  public type UpdateResult = [Types.Graphics.Result];

  /// Construct Basic terminal service from a service Core.
  public class Basic(initCore : Core) {

    var core = initCore;

    public func view(dim : Types.Dim, events : [EventInfo]) : ViewResult {
      let temp = core.clone();
      for (event in events.vals()) {
        temp.update(event);
      };
      #ok(#draw(temp.draw(dim)))
    };

    public func update(events : [EventInfo], gfxReq : GfxReq) : UpdateResult {
      for (event in events.vals()) {
        core.update(event)
      };
      []
    };
  };

}
