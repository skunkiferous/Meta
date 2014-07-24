Meta
====

The second generation, XTend-based, Meta API for Types, Networks, ...


RELEASES:
=========

v0.0.2 (2013-12-26)
===================

An optional interface for "typed" instances could allow retrieving
    the Type of an object without having to recourse to hashing.

Replace all "parent" volatile fields wit a single generic parent field in parent of MetaBase.

Packages should be created explicitly, to allow them to be extensible.
They should receive the Type instances, the way Type receives the Property instances.

Hierarchy should receive the Packages instances, the way Type receives the Property instances.

We should move to context-aware converters (Context would be owning object)

All Setters should return the instance, so we can use them for immutable types.

Move to Functors for getters and setters.

Make sure the tests are updated.

RELEASE PLAN:
=============

v0.0.3
======

Skipped ...

v0.0.4
======

DONE:
=====

Add an "empty array" instance to every type instance.

We need to have a Collection Bean property that returns the "content". That is the only way to get equals/hashCode/toString, ... to work correctly. We should also have at least size as virtual property.

The Collection Bean *interface* should provide a getter for the collection bean configuration.

The Collection "toArray" property should be renamed to "content". The rational is that the "content" need not map one-to-one with the output of toArray. This is required, so that content can be used to make the Collection Bean correctly comparable. For unordered sets, we would "sort" the content, such that is is comparable.

The "sorting" for unordered sets could go like this: if the base type is comparable, then use that. If not, sort based on hashcode. On duplicate hashcode, call equals. If not equals, then compare the toString form.

Generate a copyFrom method?

Add source code generation using Active annotations.

A Builder is basically just a Bean version of an Immutable, so we really always want both.

We might need to record some meta-information, required for the compilation of dependent projects,
into annotation on the generated/transformed source code.

If we have "read-only", "computed" properties, we need to have new property lists, which contains only "real" properties.

Check that the immutable flag is respected everywhere.

We should allow the definition of virtual properties.

The "create" method for collection properties should be called "get", with the normal get being called "getRaw".

Once we have virtual properties, we need to add some to Bean and Entity.

If we assume generic parameters are bound to instances, rather then to Types,
and this is done by defining Properties that return the generic parameters,
then the Type should have a list of those Properties.

TODO:
=====

Make sure the tests are updated.

v0.1.0
======

DONE:
=====

We need some kind of visitor pattern over the Meta-classes

Add PrimitiveProperty.toDouble

Add Interfaces for the properties

Add Property.getAny

We probably want immutable flags for Properties

Define a EnumProperty interface, extending the to-be-defined Property interfaces

An Enum property to be based on byte.

An Enum property to be based on String.

TODO:
=====

Array / Collection / Map properties

We need to detect if a property/method/type/package was "forgotten"
at the creation of it's parent.

Type creation should support parameters as well. Or should we
instead define Constructor objects, like the Properties? Constructors
are then a special case of Methods.

What about generic Builders for immutable types?
Do we need them if we have Constructor objects? Or the other way around?

Add Generics (double[]+Object[] == everything)

---Add Minimal (Double+Object) Functors---

32-bit slot property index (where long and double take two slots)

Add immutable flag to Type

Reduce Potential for circular dependency, by having the data-type of
Properties being initialized once the Hierarchy is "ready".

The data-type of properties can either be a Type of another hierarchy,
or a Class of the same hierarchy.

Add static flag to Properties, and create static subclasses, that do not
need an instance parameter in the getter/setter. Static properties do not
get serialized. Static properties should have their own "ID space".

Should we add support for Google Guice? Can Context/Scope simply be defined
as "related data" that cannot simply be accessed through navigating properties?

Add support for Object-Object converter, with reversibility

Long-As-Object properties

Add Scala-style Symbols (must NOT be user-creatable)
Symbols probably need their own Hierarchy.

Add meta-property auto-initializers
(must somehow make sure all things registered both before and after
the auto-initializers themselves are registered all get a value)
Use "HierarchyListener" for that.

A "Path" could be created from an array of Properties, and an AnyArray, in case the properties are Collections or Maps (index/map-key).

Make sure the tests are updated.

LATER
=====

DONE:
=====

TODO:
=====

Write some usable documentation, to help people get started.

Write high-level design goals.

Use the Hierarchy-Builder as a "? extends MetaBase" Factory, allowing
the concrete subclass used to be configurable, despite the static
initialization.

Compound-Type (Composition): Compound types could be implemented,
by using an array in each compound type instance, which would map
a global property ID (primitive/object) to a compound type property ID.

Review and integrate missing concepts from original Meta project.

Could be build a generic serializer on the Meta-API?

Are Properties just a special case of Context-Aware Converters?

Add "generic Enums" based on the Symbols

Add "Methods" (?)

Support fake base-classes (Make Boolean a sub-type of Number)

Do we even care about "non-static" Types?

Add Read-only properties for Java-Lang types

Add support for annotations (in some cross-platform way)

The Meta-API must also support Exceptions types

Make sure the tests are updated.

UNPROCESSED:
============

Create an @DefaultValue annotation

Type instances should offer an array of all Properties in alphabetical order.

Add API to allow Processors to order themselves before or after some other Processor.

Generate a compute-a-difference method?

Reset method for Properties (requires use of default).

Log error if more then one file is used per project during annotation processing.

Refactor annotation processing to move access to internal Xtend API in a separate class.

Cache generated new class names in the "register globals" phase, so the processing only happens once.

Design some functionality to "get all types" at runtime, based on the fact that all dependencies
are "frozen and available" when compiling, and all types in the current project are within the
currently processed file. We might want to generate a list-of-types if the "generate" phase.

We should have a "Role" hierarchy (extensible enum or marker interfaces) that "qualifies" the
properties, and can be queried at runtime to drive part of the code generation.

The (original) Meta API IDs should be based on an hexadecimal String, instead of a long.
We could then safely use two bytes per level, at every level, without being limited to 8 bytes.
The Network Coordination should use those String IDs too.

We need a way to make "groups of hierarchies" somehow "linear", so we can define IDs that are
global to the whole group. Maybe we can have a root/primary hierarchy, and the "group ID" is
managed by the root.

How do we solve the "virtually infinite" JRE "hierarchy"?

The Type of a Property can either come from another Hierarchy as Type, or from the same Hierarchy
as Class. The actual Type instance can only be resolved at the Hierarchy construction time.

Complete validation is possible only at Hierarchy construction time.

Allowing the type of a property to become more specific in a sub-type cannot be allowed, as it
would mean the setter of the sub-type accepts only a more specific type, which is not valid in Java.

If for every type of Property (int, Object, ...) the Type instance defined a xxxOffset value,
identifying how many properties of that type have already been defined, then we could have the
global IDs computed as "type.xxxOffset + localID", instead of recorded in each property.

When we add support for Methods, we should have the Properties reference the getter and setter
Methods, instead of using lambdas.

We need a SELF-type. It would be replaced by the type using it. WHen used as parameter, no compile-time check is performed, so a runtime check is needed.

Should the serialization simulate "composition" instead of "inheritance"? The "wrapper object" could use the "component type" as a key/field-name.

Factories could be implicitly defined by calling a field newXXX, OR we have a @Factory annotation, and all fields become newXXX. One Factory per package would be simpler.

If we limit the bean properties to primitives, Beans, and a small set of pre-defined types, we could generate a "tree size" for each Type. But restricting non-bean types to a fixed list is not good.

We could enable the creation and application of "patches", by serializing the "selected" (dirty) properties only.

We could allow the definition of "real" constants in the beans, by having the fields (which are constants anyway) have a specified value. Could the constant values be overwritten in subtypes? This would require the constants to be turned to "getters" that return a constant.

For each "parent", we should compute the number of properties. The parent with the greatest number of properties should be used as base-class.

Apache Common Lang defines mutable primitive types. Maybe those could be used for "primitive collections"?

We should add "implicit extension", called "retrofitting", to our feature-set. This would allow forcing all instances of type X in the application to also implement type Y, such that this relationship is defined on extended type, and not on the extending type.

An alternative to bytecode manipulation to implement retrofitting is to use the "extender pattern", where composition adds the additional retrofitted data. We could use either an extension array, or a linked list, of extensions, or just one mutiple-inherited extension.

Beans could offer a "map view" of their properties. Any code that "knows" about the Properties does not need to use a map view, so we should use Strings as the map key.

If the API type of a property is NOT a bean, then we should check that no bean can be set in this property.

If we force the use of a "unique prefix" to prevent name clashes, this prefix should represent the "Maven group-ID", rather then then Maven artifact-ID or the hierarchy-ID. Group-IDs are orthogonal to hierarchies.

Hierarchies should take the group prefix as parameter and validate all "names".

Could we have one "stateful" interceptor per reactor? Immutable "traveling" beans would use a stateless global interceptor?

All "convertible" should be immutable.

"Accepted types" are then primitives, immutable, array/collection, and beans.

Bean properties should have their own property list in the Type.

We need a method in the Bean that takes some kind of "filter", and returns all the "matching properties", and some annotation that allows generating a "getter" returning the "matching properties" based on some pre-defined filter.

Entities should be Blades.

We also need an "invalid" flag. I'm not sure yet how the propagation should work, but the flag would indicate that the bean *cannot be serialized/saved*, and so any parent cannot be serialized either.

I need a better name for my "Beans"; they aren't really beans (like EJB beans). Maybe I can use the term "trait", in which case I could rename the whole API to "Traitor".

Should setting the immutable flag to true cause a propagation to all children?

The bean reference to it's parent should also include either the property, or the collection index or the map key.

Can the parent of an immutable bean change? If we also store the parent property and optional index/key, we can't even mutate it atomically. So should we require from immutable that their parent be either null or also immutable?

Using immutability propagation would ensure that "Requests" be thread-safe.

Instead of defining simply "properties" and "constants", we should switch to defining every property to have a "scope", where "instance scope" is the default scope, and "constant" is just one possible scope.

"Exact type matching" (for collections and properties) should use the Type of a bean, instead of it's class (which is used for non-beans).

The part of the bean processor that generates the property code should be separated into it's own class, so that property generation become customizable.

When using extension/retrofitting, there must be *no* overlap between the Bean and all it's extensions, and between the extensions themselves.

Extensions need a back-reference to the Bean itself. This will allow something like a castTo() method to also work correctly on extensions.

Can access rights have a direct effect on the Bean design? The access rights should be based on the owning Entity of a Bean. The interceptor can be in charge of doing that validation.

Since both JSON and serialization can be realized using the Properties accessors, they should not be part of the class, but rather be defined in the Type. This would allow JSON output and serialization of types whose implementation was not "generated" (third-party types).

What if we needed to access historical data? Do we need some kind of "old" flag in Properties, so the "old values" can still be read (until the old Properties are dropped completely)? Or can we instead have the old property values read into a generic object, which can be discarded, after the values where "migrated" to the new schema?

We should add a list of "Listeners" to (non-virtual) Properties, such that those listeners are executed, when a property change. They would be "static" listeners, but that already solves many problems. That probably needs to be updatable dynamically.

Allow the definition of virtual properties "dependencies" and a "Refresh" handler that gets called on first creation/load of the object, and then every time a dependency changes. Note: Being able to depend on your *own* Properties only is very limiting.

We need a Bean graph visitor. It would use the Properties and allow either either visiting all properties, or just the object properties.

Is virtual properties the same as transient properties? I think the two are mostly orthogonal. Transient properties are normal properties that are not saved (but could be in toString). Virtual properties are not normally "allocated space", but we could have "cached" virtual properties, and those would basically be transient properties.

We should allow the definition of virtual properties just by annotating the interface field with an annotation that defines the getter and setter implementations as Strings.

Traits/Beans can also be considered a schema definition (if we keep the code out).

We do need to use our serialization API, because we will have to deal with *versioning*.

We could define "path" within the object "tree" as an array/list of Property instances (all but the last one need to be Object-Properties). But what about collections? If we don't try to add the ability to target a specific position/key, then we can just return *all* values of a collection. So the result to a "path query" will be an iterator, which can return 0 (one of the path values is null), one, or more (one of the path values is a collection) results.

The Beans API of Meta should allow copying to/from *non-Meta* implementations of the Bean interfaces, in case we are forced to generate implementations with other technologies, like GWT auto-beans.

Add Interfaces for all the meta-types
