/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.types.impl;

import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.reflections.Reflections;

import com.blockwithme.meta.Statics;
import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.annotations.impl.AnnotationReaderImpl;
import com.blockwithme.meta.types.Access;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;
import com.blockwithme.meta.types.TypeRange;
import com.blockwithme.meta.types.annotations.impl.PropertyAnnotationProcessor;
import com.blockwithme.meta.types.annotations.impl.TypeAnnotationProcessor;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.frames.FramedGraph;
import com.tinkerpop.frames.FramedGraphFactory;
import com.tinkerpop.frames.VertexFrame;
import com.tinkerpop.frames.modules.gremlingroovy.GremlinGroovyModule;
import com.tinkerpop.frames.modules.javahandler.JavaHandlerModule;

/**
 * TypeGraphBuilder builds a Framed graph using reflection by inspecting all
 * classes in the desired packages. Most meta-information comes from annotations.
 *
 * @author monster
 */
public class TypeGraphBuilder {
    /** Creates a new basic type, of the desired kind. */
    public static Type buildBasicType(final FramedGraph<TinkerGraph> graph,
            final Class<?> type, final Kind kind,
            final Map<Class<?>, Type> types) {
        final String name;
        if (!type.isArray()) {
            name = type.getName();
        } else {
            // Default array name for primitive types is not readable...
            name = type.getComponentType().getName() + "[]";
        }
        final Type result = graph.addVertex(name, Type.class);
        result.setName(name);
        result.setKind(kind);
        // Assume public
        result.setAccess(Access.Public);
        // Assume no "properties" for data
        result.setBiggerThanParents(false);
        // Assume default serialisation
        result.setPersistence(Arrays.asList("java.io.Serializable"));
        result.setType(type);
        types.put(type, result);
        return result;
    }

    /** Creates a new basic type. Kind is either Data or Array. */
    public static Type buildBasicType(final FramedGraph<TinkerGraph> graph,
            final Class<?> type, final Map<Class<?>, Type> types) {
        return buildBasicType(graph, type, type.isArray() ? Kind.Array
                : Kind.Data, types);
    }

    /** Creates the basic JDK Type instances, to be used by user types. */
    public void buildBasicTypes(final FramedGraph<TinkerGraph> graph,
            final Map<Class<?>, Type> types) {
        // TODO Most basic types have been commented away to make debugging easier.

//        buildBasicType(graph, void.class, types);
//        buildBasicType(graph, boolean.class, types);
//        buildBasicType(graph, byte.class, types);
//        buildBasicType(graph, char.class, types);
//        buildBasicType(graph, short.class, types);
//        buildBasicType(graph, int.class, types);
//        buildBasicType(graph, long.class, types);
//        buildBasicType(graph, float.class, types);
//        buildBasicType(graph, double.class, types);
//
//        buildBasicType(graph, Void.class, types);
//        final Type number = buildBasicType(graph, Number.class, types);
//        buildBasicType(graph, Boolean.class, types);
//        buildBasicType(graph, Byte.class).addParent(number, types);
//        buildBasicType(graph, Character.class, types);
//        buildBasicType(graph, Short.class).addParent(number, types);
//        buildBasicType(graph, Integer.class).addParent(number, types);
//        buildBasicType(graph, Long.class).addParent(number, types);
//        buildBasicType(graph, Float.class).addParent(number, types);
//        buildBasicType(graph, Double.class).addParent(number, types);

        buildBasicType(graph, String.class, types);
//        buildBasicType(graph, Class.class, types);
//
//        buildBasicType(graph, boolean[].class, types);
//        buildBasicType(graph, byte[].class, types);
//        buildBasicType(graph, char[].class, types);
//        buildBasicType(graph, short[].class, types);
//        buildBasicType(graph, int[].class, types);
//        buildBasicType(graph, long[].class, types);
//        buildBasicType(graph, float[].class, types);
//        buildBasicType(graph, double[].class, types);
//        buildBasicType(graph, String[].class, types);
//        buildBasicType(graph, Class[].class, types);
//
//        final Type iterable = buildBasicType(graph, Iterable.class, types);
//        final Type collection = buildBasicType(graph, Collection.class, types);
//        collection.addParent(iterable, types);
//        final Type set = buildBasicType(graph, Set.class, types);
//        set.addParent(collection, types);
//        buildBasicType(graph, List.class).addParent(collection, types);
        final Type map = buildBasicType(graph, Map.class, types);
//        map.addParent(collection, types);
//        buildBasicType(graph, SortedMap.class).addParent(map, types);
//        buildBasicType(graph, SortedSet.class).addParent(set, types);
    }

    /** Creates a new empty Framed graph. */
    public FramedGraph<TinkerGraph> newGraph() {
        final TinkerGraph baseGraph = new TinkerGraph();
        final FramedGraphFactory factory = new FramedGraphFactory(
                new GremlinGroovyModule(), new JavaHandlerModule(),
                Statics.module());
        return factory.create(baseGraph);
    }

    /**
     * Converts the allowed annotation types to the allowed GraphML types.
     * Annotations support any primitive, String, Class and enums, as well as
     * arrays thereof.
     * GraphML does not support byte, char, short, enums (but left as is),
     * class (but left as is), nor arrays (must be turned to Lists, for easy
     * deserialisation)
     */
    private static Object convert(final Object value) {
        if (value != null) {
            final Class<?> type = value.getClass();
            if (!type.isArray()) {
                // Not array: check unsupported primitive types
                if (type == Character.class) {
                    return (int) ((Character) value).charValue();
                }
                if ((type == Byte.class) || (type == Short.class)) {
                    return ((Number) value).intValue();
                }
            } else if (type.getComponentType().isPrimitive()) {
                // primitive array: turned to wrapper list :(
                final int len = Array.getLength(value);
                final List<Object> list = new ArrayList<>(len);
                for (int i = 0; i < len; i++) {
                    list.add(convert(Array.get(value, i)));
                }
                return list;
            } else {
                // Object array; probably Class or enum
                final Object[] array = (Object[]) value;
                final int len = array.length;
                final List<Object> list = new ArrayList<>(len);
                for (int i = 0; i < len; i++) {
                    list.add(convert(array[i]));
                }
                return list;
            }
        }
        return value;
    }

    /** Copies the properties from a Map to a Vertex. */
    private static void copyProps(final PropMap src, final VertexFrame dst) {
        final Vertex vertex = dst.asVertex();
        for (final String key : src.keySet()) {
            final Object value = convert(src.get(key));
            if (value != null) {
                // Null converted properties are dropped
                vertex.setProperty(key, value);
            }
        }
    }

    /** Builds a Frame Type from an AnnotatedType. */
    private Type buildType(final FramedGraph<TinkerGraph> graph,
            final AnnotatedType at, final Bundle bundle) {
        final Type result = graph.addVertex(at.getType().getName(), Type.class);
        final PropMap data = at.getTypeData().get(
                com.blockwithme.meta.types.annotations.Type.class);
        copyProps(data, result);
        result.setBundle(bundle);
        return result;
    }

    /** Search and return pre-existing types. Array-of are created automatically here. */
    private static Type getType(final Map<Class<?>, Type> types,
            final Class<?> wanted, final FramedGraph<TinkerGraph> graph) {
        Type result = types.get(wanted);
        if ((result == null) && wanted.isArray()) {
            // Auto-create array types
            result = buildBasicType(graph, wanted, types);
        }
        return Objects.requireNonNull(result, wanted + " not found");
    }

    /** Once all the types themselves are created, create Properties ... */
    private void buildPropertiesTypeRangesContainers(
            final FramedGraph<TinkerGraph> graph, final AnnotatedType at,
            final Type type, final Map<Class<?>, Type> types) {
        // Check all methods to see if they are Properties.
        // Note that only *getters* should be annotated!
        for (final Method m : at.getMethods()) {
            final Map<Class<?>, PropMap> map = at.getMethodData(m);
            final PropMap propData = map
                    .get(com.blockwithme.meta.types.annotations.Property.class);
            if (propData != null) {
                // First, the property itself
                final String id = at.getType().getName() + "."
                        + Statics.getPropertyNameFor(m);
                final Property prop = graph.addVertex(id, Property.class);
                final PropMap typeRangeData = propData.remove("typeRange",
                        PropMap.class);
                copyProps(propData, prop);
                prop.setBundle(type.getBundle());
                type.addProperty(prop);
                prop.setType(type);
                // then it's type-range
                final TypeRange typeRange = graph.addVertex(id + ".typeRange",
                        TypeRange.class);
                copyProps(typeRangeData, typeRange);
                typeRange.setBundle(type.getBundle());
                typeRange.setDeclaredType(getType(types, m.getReturnType(),
                        graph));
                for (final Class<?> accepted : typeRangeData.get("accepts",
                        Class[].class)) {
                    typeRange.addAcceptedType(getType(types, accepted, graph));
                }
                for (final Class<?> rejected : typeRangeData.get("rejects",
                        Class[].class)) {
                    typeRange.addRejectedType(getType(types, rejected, graph));
                }
                prop.setTypeRange(typeRange);
                // Then, register property as container of other types
                for (final Type t : types.values()) {
                    if (typeRange.accept(t)) {
                        t.addContainer(prop);
                    }
                }
            }
        }
    }

    /**
     * From an empty Framed graph, builds the graph using reflection, by
     * checking all the classes returned by packages.
     *
     * @param graph the empty graph
     * @param context and optional configuration context
     * @param packages returns all types to import in the graph
     * @param bundle the bundle to which all the types belong
     *
     * TODO I don't think that we can use Reflections in OSGi so we need an
     * alternate mean of finding classes. I think we need:
     * BundleWiring.listResources() for that.
     */
    public void build(final FramedGraph<TinkerGraph> graph,
            final PropMap context, final Reflections packages,
            final Bundle bundle) {
        // Read all the meta-info from the types
        final AnnotationReader ar = new AnnotationReaderImpl(context);
        ar.withPostProcessor(com.blockwithme.meta.types.annotations.Type.class,
                new TypeAnnotationProcessor());
        ar.withPostProcessor(
                com.blockwithme.meta.types.annotations.Property.class,
                new PropertyAnnotationProcessor());
        @SuppressWarnings("unchecked")
        final Map<String, AnnotatedType> metaInfo = ar.read(packages,
                com.blockwithme.meta.types.annotations.Type.class,
                com.blockwithme.meta.types.annotations.Property.class);

        final Map<Class<?>, Type> types = new HashMap<Class<?>, Type>();
        // Registers the JDK types
        buildBasicTypes(graph, types);
        // Registers the user types
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = buildType(graph, at, bundle);
            types.put(at.getType(), type);
        }
        // Add the properties to the user types
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = types.get(at.getType());
            buildPropertiesTypeRangesContainers(graph, at, type, types);
        }
    }
}
