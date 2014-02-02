package model;

import java.util.Collection;

import javax.inject.Provider;

import org.eclipse.xtext.xbase.lib.Functions;

import com.blockwithme.meta.Hierarchy;
import com.blockwithme.meta.HierarchyBuilder;
import com.blockwithme.meta.IntPropertyAccessor;
import com.blockwithme.meta.JavaMeta;
import com.blockwithme.meta.Kind;
import com.blockwithme.meta.ObjectPropertyAccessor;
import com.blockwithme.meta.TrueIntegerProperty;
import com.blockwithme.meta.TypePackage;

public interface Model {
    ////////////////////////////////////////////////////////////
    //                       "Provided" API interfaces
    ////////////////////////////////////////////////////////////

    /** Base for all Type meta-objects */
    public interface Type {
        // "properties" should be a getter ...
        Property[] properties = new Property[0];

        // Creates a default new instance
        Object create();
//
//        // Creates an initialized new instance
//        Object createFromJSON(String json);
        // TODO
    }

    /** Base for all Property meta-objects */
    public interface Property {
        // "id" should be a getter ...
        int id = 42;
        // TODO
    }

    public interface IntProperty extends Property {
        int getValue(Object obj);

        void setValue(Object obj, int newValue);
        // TODO
    }

    public interface ObjectProperty<E> extends Property {
        E getValue(Object obj);

        void setValue(Object obj, E newValue);
        // TODO
    }

    /** Base for all data/bean objects */
    public interface Base {
        Type getType();

        boolean isImmutable();

        long hashCode64();
//
//        /** Always a full mutable copy */
//        Base copy();
//
//        /** Always an immutable copy */
//        Base snapshot();
//
//        /** Always a lightweight mutable copy */
//        Base wrapper();
    }

    /** "Internal" Base for all data/bean objects */
    public interface _Base extends Base {
        boolean isDirty();

        boolean isDirty(Property prop);

        void setDirty(Property prop);

        void getChangedProperty(Collection<Property> changed);

        void clean();

        _Base getDelegate();

        void setDelegate(_Base delegate);

        Interceptor getInterceptor();

        void setInterceptor(Interceptor newInterceptor);
    }

    /** Interceptor allows "delegation", "validation", ... */
    public interface Interceptor {
        int getIntProperty(_Base instance, IntProperty prop, int value);

        int setIntProperty(_Base instance, IntProperty prop, int oldValue,
                int newValue);

        <E> E getObjectProperty(_Base instance, ObjectProperty<E> prop, E value);

        <E> E setObjectProperty(_Base instance, ObjectProperty<E> prop,
                E oldValue, E newValue);
    }

    ////////////////////////////////////////////////////////////
    //                       "Provided" API implementations
    ////////////////////////////////////////////////////////////

    /** Base impl for all data/bean objects (maybe remove requirement later) */
    public abstract class BaseImpl implements _Base {
        private boolean immutable;
        protected Interceptor interceptor;
        // 64 "dirty" flags; maximum 64 properties!
        private long dirty;
        private Type type;
        private String toString;
        private long hashCode64;
        // Allows re-using the same generated code for "wrappers" ...
        protected _Base delegate;

        @Override
        public final Type getType() {
            return type;
        }

        @Override
        public final boolean isImmutable() {
            return immutable;
        }

        @Override
        public final boolean isDirty() {
            return dirty != 0;
        }

        @Override
        public final boolean isDirty(final Property prop) {
            // "id" should be a getter ...
            return (dirty & (1L >> prop.id)) != 0;
        }

        @Override
        public final void setDirty(final Property prop) {
            if (immutable) {
                throw new UnsupportedOperationException(this + " is immutable!");
            }
            // "id" should be a getter ...
            dirty |= (1L >> prop.id);
            hashCode64 = 0;
            toString = null;
        }

        @Override
        public final void clean() {
            if (immutable) {
                throw new UnsupportedOperationException(this + " is immutable!");
            }
            dirty = 0;
            hashCode64 = 0;
            toString = null;
        }

        @Override
        public final void getChangedProperty(final Collection<Property> changed) {
            changed.clear();
            if (isDirty()) {
                for (final Property p : type.properties) {
                    if (isDirty(p)) {
                        changed.add(p);
                    }
                }
            }
        }

        @Override
        public final long hashCode64() {
            if (hashCode64 == 0) {
                // TODO Compute hashcode lazily from Properties
                if (hashCode64 == 0) {
                    hashCode64 = 1;
                }
            }
            return hashCode64;
        }

        @Override
        public final int hashCode() {
            final long value = hashCode64();
            return (int) (value ^ (value >>> 32));
        }

        @Override
        public final String toString() {
            if (toString == null) {
                // TODO Compute toString lazily from Properties
                // Use JSON format
                toString = getClass().getSimpleName();
            }
            return toString;
        }

        @Override
        public final boolean equals(final Object obj) {
            if ((obj == null) || (obj.getClass() != getClass())) {
                return false;
            }
            if (obj == this) {
                return true;
            }
            final BaseImpl other = (BaseImpl) obj;
            if (hashCode64() != other.hashCode64()) {
                return false;
            }
            // TODO Check equality based on Properties
            // (With same "good" hashCode64, inequality here is very unlikely)
            return true;
        }

        @Override
        public final _Base getDelegate() {
            return delegate;
        }

        @Override
        public final void setDelegate(final _Base delegate) {
            if ((delegate != null) && (delegate.getClass() != getClass())) {
                throw new IllegalArgumentException("Expected type: "
                        + getClass() + " Actual type: " + delegate.getClass());
            }
            // Does NOT affect "dirty state"
            this.delegate = delegate;
        }

        @Override
        public final Interceptor getInterceptor() {
            return interceptor;
        }

        @Override
        public final void setInterceptor(final Interceptor interceptor) {
            if (interceptor == null) {
                throw new IllegalArgumentException("interceptor cannot be null");
            }
            // Does NOT affect "dirty state"
            this.interceptor = interceptor;
        }
//
//        /** Copies the content of another instance of the same type. */
//        private void copyFrom(final BaseImpl other) {
//            if (other == null) {
//                throw new IllegalArgumentException("other cannot be null");
//            }
//            if (other.getClass() != getClass()) {
//                throw new IllegalArgumentException("Expected type: "
//                        + getClass() + " Actual type: " + other.getClass());
//            }
//            // TODO
//        }
    }

    /** Singleton, used for all normal "beans" */
    class DefaultInterceptor implements Interceptor {
        /** Default instance */
        public static final Interceptor INSTANCE = new DefaultInterceptor();

        @Override
        public int getIntProperty(final _Base instance, final IntProperty prop,
                final int value) {
            return value;
        }

        @Override
        public int setIntProperty(final _Base instance, final IntProperty prop,
                final int oldValue, final int newValue) {
            if (oldValue != newValue) {
                instance.setDirty(prop);
            }
            return newValue;
        }

        @Override
        public <E> E getObjectProperty(final _Base instance,
                final ObjectProperty<E> prop, final E value) {
            return value;
        }

        @Override
        public <E> E setObjectProperty(final _Base instance,
                final ObjectProperty<E> prop, final E oldValue, final E newValue) {
            if ((oldValue != newValue)
                    && (oldValue == null || !oldValue.equals(newValue))) {
                instance.setDirty(prop);
            }
            return newValue;
        }
    }

    /** Singleton, used for all normal "wrappers" (delegate can be immutable) */
    class WrapperInterceptor implements Interceptor {
        /** Default instance */
        public static final Interceptor INSTANCE = new WrapperInterceptor();

        @Override
        public int getIntProperty(final _Base instance, final IntProperty prop,
                final int value) {
            final _Base delegate = instance.getDelegate();
            if ((delegate == null) || instance.isDirty(prop)) {
                return value;
            }
            return prop.getValue(delegate);
        }

        @Override
        public int setIntProperty(final _Base instance, final IntProperty prop,
                final int oldValue, final int newValue) {
            if (oldValue != newValue) {
                instance.setDirty(prop);
            }
            return newValue;
        }

        @Override
        public <E> E getObjectProperty(final _Base instance,
                final ObjectProperty<E> prop, final E value) {
            final _Base delegate = instance.getDelegate();
            if ((delegate == null) || instance.isDirty(prop)) {
                return value;
            }
            return prop.getValue(delegate);
        }

        @Override
        public <E> E setObjectProperty(final _Base instance,
                final ObjectProperty<E> prop, final E oldValue, final E newValue) {
            if ((oldValue != newValue)
                    && (oldValue == null || !oldValue.equals(newValue))) {
                instance.setDirty(prop);
            }
            return newValue;
        }
    }

    /////////////////////////////////////////////////////////////////////////
    //                            User-written code
    /////////////////////////////////////////////////////////////////////////

//    @Trait(concrete=false)
//    public interface Aged {
//        int age;
//    }

//    @Trait(concrete=false)
//    public interface Named {
//        String name;
//    }

//    @Trait
//    public interface Person extends Aged, Named {
//        String job;
//    }

    //////////////////////////////////////////////////////////////////////////////
    //                             Generated code interfaces
    //////////////////////////////////////////////////////////////////////////////

    public interface Aged extends Base {
        int getAge();

        Aged setAge(int age);
    }

    public interface Named extends Base {
        String getName();

        Named setName(String name);
    }

    public interface Person extends Aged, Named {
        String getJob();

        Person setJob(String job);

        // To get a nice fluent API *without generics*, I would need to
        // re-define those, and then override the base setters in the impl class.
        // Problem is, in a deep hierarchy, the real setter could be "wrapped"
        // many times, leading to inefficiency:
        // Warrior setAge(int) => Player setAge(int) => Person setAge(int) => Aged setAge(int) !
//        Person setAge(int age);
//        Person setName(String name);
    }

    public interface Meta {
        public static final HierarchyBuilder BUILDER = new HierarchyBuilder(
                "model"/*fully-qualified-package-name*/);
        public static final TrueIntegerProperty<Aged> AGE_PROP = BUILDER
                .newIntegerProperty(Aged.class, "age",
                        new IntPropertyAccessor<Aged>() {
                            @Override
                            public int apply(final Aged obj) {
                                return obj.getAge();
                            }

                            @Override
                            public Aged apply(final Aged obj, final int value) {
                                return obj.setAge(value);
                            }
                        });
        public static final com.blockwithme.meta.Type<Aged> AGED_TYPE = BUILDER
                .newType(Aged.class, BUILDER.createProvider(Aged.class),
                        Kind.Trait, new com.blockwithme.meta.Type<?>[] {},
                        AGE_PROP);

        public static final com.blockwithme.meta.ObjectProperty<Named, String> NAME_PROP = BUILDER
                .newObjectProperty(Named.class, "name", String.class, true,
                        true, true,
                        new ObjectPropertyAccessor<Named, String>() {
                            @Override
                            public String apply(final Named obj) {
                                return obj.getName();
                            }

                            @Override
                            public Named apply(final Named obj,
                                    final String value) {
                                return obj.setName(value);
                            }
                        });
        public static final com.blockwithme.meta.Type<Named> NAMED_TYPE = BUILDER
                .newType(Named.class, BUILDER.createProvider(Named.class),
                        Kind.Trait, new com.blockwithme.meta.Type<?>[] {},
                        NAME_PROP);

        public static final com.blockwithme.meta.ObjectProperty<Person, String> JOB_PROP = BUILDER
                .newObjectProperty(Person.class, "job", String.class, true,
                        true, true,
                        new ObjectPropertyAccessor<Person, String>() {
                            @Override
                            public String apply(final Person obj) {
                                return obj.getJob();
                            }

                            @Override
                            public Person apply(final Person obj,
                                    final String value) {
                                return obj.setJob(value);
                            }
                        });
        public static final com.blockwithme.meta.Type<Person> PERSON_TYPE = BUILDER
                .newType(Person.class, BUILDER.createProvider(Person.class),
                        Kind.Trait, new com.blockwithme.meta.Type<?>[] {
                                AGED_TYPE, NAMED_TYPE }, JOB_PROP);
        public static final TypePackage PACKAGE = BUILDER.newTypePackage(
                AGED_TYPE, NAMED_TYPE, PERSON_TYPE);
        public static final Hierarchy HIERARCHY = BUILDER.newHierarchy(
                new TypePackage[] { PACKAGE }, JavaMeta.HIERARCHY);
    }

    //////////////////////////////////////////////////////////////////////////////
    //                             Generated code implementations
    //////////////////////////////////////////////////////////////////////////////

    public class AgedImpl extends BaseImpl implements Aged {
        // Injected? Public so they are available when fake multiple
        // inheritance requires code duplication.
        // Note: *Not* a per-Type/per-Property special class in real code.
        public static volatile IntProperty AGE = null/* TODO */;

        private int age;

        @Override
        public final int getAge() {
            return interceptor.getIntProperty(this, AgedImpl.AGE, this.age);
        }

        @Override
        public final Aged setAge(final int age) {
            this.age = interceptor.setIntProperty(this, AgedImpl.AGE, getAge(),
                    age);
            return this;
        }
    }

    public class AgedImplProvider implements Provider<Aged>,
            Functions.Function0<Aged> {
        @Override
        public Aged apply() {
            return new AgedImpl();
        }

        @Override
        public Aged get() {
            return new AgedImpl();
        }
    }

    ///////////////////////////////////////////////////////////////

    public class NamedImpl extends BaseImpl implements Named {
        // Injected? Public so they are available when fake multiple
        // inheritance requires code duplication.
        // Note: *Not* a per-Type/per-Property special class in real code.
        public static volatile ObjectProperty<String> NAME = null/* TODO */;

        private String name;

        @Override
        public final String getName() {
            return interceptor.getObjectProperty(this, NamedImpl.NAME,
                    this.name);
        }

        @Override
        public final Named setName(final String name) {
            this.name = interceptor.setObjectProperty(this, NamedImpl.NAME,
                    getName(), name);
            return this;
        }
    }

    public class NamedImplProvider implements Provider<Named>,
            Functions.Function0<Named> {
        @Override
        public Named apply() {
            return new NamedImpl();
        }

        @Override
        public Named get() {
            return new NamedImpl();
        }
    }

    //////////////////////////////////////////////////////////////////

    public class PersonImpl extends AgedImpl implements Person {
        // Injected? Public so they are available when fake multiple
        // inheritance requires code duplication.
        // Note: *Not* a per-Type/per-Property special class in real code.
        public static volatile ObjectProperty<String> JOB = null/* TODO */;

        private String job;

        @Override
        public final String getJob() {
            return interceptor
                    .getObjectProperty(this, PersonImpl.JOB, this.job);
        }

        @Override
        public final Person setJob(final String job) {
            this.job = interceptor.setObjectProperty(this, PersonImpl.JOB,
                    getJob(), job);
            return this;
        }

        /////////////////////////////////////////////////////////////
        // This is "duplicated code" (unavoidable). If we enforce maximum
        // of 2 base types, this is the code from the "second" base type
        /////////////////////////////////////////////////////////////
        private String name;

        @Override
        public final String getName() {
            return interceptor.getObjectProperty(this, NamedImpl.NAME,
                    this.name);
        }

        @Override
        public final Named setName(final String name) {
            this.name = interceptor.setObjectProperty(this, NamedImpl.NAME,
                    getName(), name);
            return this;
        }
    }

    public class PersonImplProvider implements Provider<Person>,
            Functions.Function0<Person> {
        @Override
        public Person apply() {
            return new PersonImpl();
        }

        @Override
        public Person get() {
            return new PersonImpl();
        }
    }
}
