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
package com.blockwithme.meta;

import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;

import org.reflections.Reflections;

import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Feature;
import com.tinkerpop.blueprints.Direction;
import com.tinkerpop.blueprints.Element;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.EdgeFrame;
import com.tinkerpop.frames.VertexFrame;
import com.tinkerpop.frames.modules.Module;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;
import com.tinkerpop.frames.modules.typedgraph.TypedGraphModuleBuilder;

/**
 * Divers helper methods.
 *
 * TODO Eventually, it should be our goal to remove all usage of @GremlinGroovy
 * and create @JavaHandler methods instead. Most likely, reusable code,
 * like searching for a Vertex by "name" can be put here, and the JavaHandler
 * can then simply delegate here.
 *
 * @author monster
 */
public class Statics {

    /** All "Frames" */
    private static Set<Class<?>> typedInterfaces;

    /** toString() for a Element (bothe Vertex and Edge). */
    public static String toString(final Element elem) {
        final StringBuilder buf = new StringBuilder();
        buf.append(elem.getProperty("class")).append("(id=")
                .append(elem.getId());
        final Set<String> keyes = elem.getPropertyKeys();
        for (final String key : new TreeSet<String>(keyes)) {
            if (!"class".equals(key)) {
                buf.append(",").append(key).append("=")
                        .append(elem.getProperty(key));
            }
        }
        buf.append(")");
        return buf.toString();
    }

    /** toString() for a VertexFrame. */
    public static String toString(final VertexFrame vertex) {
        return toString(vertex.asVertex());
    }

    /** toString() for a EdgeFrame. */
    public static String toString(final EdgeFrame edge) {
        return toString(edge.asEdge());
    }

    /** Finds all the interfaces annotated with TypeValue. */
    public static Set<Class<?>> typedInterfaces() {
        if (typedInterfaces == null) {
            final Reflections reflections = new Reflections(
                    "com.blockwithme.meta");
            typedInterfaces = reflections
                    .getTypesAnnotatedWith(TypeValue.class);
        }
        return typedInterfaces;
    }

    /** Creates a TypedGraphModule based on all the interfaces annotated with TypeValue. */
    public static Module module() {
        final TypedGraphModuleBuilder builder = new TypedGraphModuleBuilder();
        for (final Class<?> cls : typedInterfaces()) {
            builder.withClass(cls);
        }
        return builder.build();
    }

    /** Converts a version string to an int. */
    public static int versionToInt(final String version) {
        // TDOD This code surely exists somewhere else too ...
        // It can probably be provided by OSGi when we switch to it.
        if ((version == null) || version.isEmpty()) {
            return 0;
        }
        int major = 0;
        int minor = 0;
        int incremental = 0;
        int index = version.indexOf('.');
        if (index >= 0) {
            major = Integer.parseInt(version.substring(0, index));
            String rest = version.substring(index + 1);
            index = rest.indexOf('.');
            if (index >= 0) {
                minor = Integer.parseInt(rest.substring(0, index));
                rest = rest.substring(index + 1);
                index = rest.indexOf('.');
                if (index >= 0) {
                    incremental = Integer.parseInt(rest.substring(0, index));
                }
            }
        }
        if ((major < 0) || (major >= 1024)) {
            throw new IllegalArgumentException(version);
        }
        if ((minor < 0) || (minor >= 1024)) {
            throw new IllegalArgumentException(version);
        }
        if ((incremental < 0) || (incremental >= 2048)) {
            throw new IllegalArgumentException(version);
        }
        return major * 1024 * 2048 + minor * 2048 + incremental;
    }

    /** Try to do some automated "generic" conversion */
    @SuppressWarnings("unchecked")
    public static <E> E convert(final Object value, final Class<E> type) {
        if ((value == null) || type.isInstance(value) || (type == Object.class)) {
            return (E) value;
        }
        if (type == String.class) {
            if (value instanceof Class) {
                return (E) ((Class<?>) value).getName();
            }
            return (E) value.toString();
        }
        if (value instanceof String) {
            final String str = (String) value;
            if (type.isInstance(Class.class)) {
                try {
                    return (E) Class.forName(str);
                } catch (final ClassNotFoundException e) {
                    throw new IllegalStateException(e);
                }
            }
            if (type == Boolean.class) {
                return (E) new Boolean(str);
            }
            if (type == Byte.class) {
                return (E) new Byte(str);
            }
            if (type == Short.class) {
                return (E) new Short(str);
            }
            if (type == Character.class) {
                return (E) (Character) str.charAt(0);
            }
            if (type == Integer.class) {
                return (E) new Integer(str);
            }
            if (type == Long.class) {
                return (E) new Long(str);
            }
            if (type == Float.class) {
                return (E) new Float(str);
            }
            if (type == Double.class) {
                return (E) new Double(str);
            }
        }
        if (value.getClass().isArray() && type.isArray()) {
            final int len = Array.getLength(value);
            final Class<?> componentType = type.getComponentType();
            final Object result = Array.newInstance(componentType, len);
            for (int i = 0; i < len; i++) {
                final Object o = Array.get(value, i);
                Array.set(result, i, convert(o, componentType));
            }
            return (E) result;
        }
        throw new IllegalStateException("Cannot convert " + value.getClass()
                + " to " + type);
    }

    /**
     * Returns all the bundles depended on, by this "feature".
     */
    public static Vertex[] allBundles(final Vertex appFeature) {
        final Vertex rootBundle = Objects.requireNonNull(appFeature)
                .getVertices(Direction.OUT, "bundle").iterator().next();
        final List<Vertex> todo = new ArrayList<>();
        final List<Vertex> done = new ArrayList<>();
        todo.add(rootBundle);
        while (!todo.isEmpty()) {
            final Vertex bundle = todo.remove(todo.size() - 1);
            done.add(bundle);
            for (final Vertex dep : bundle.getVertices(Direction.OUT,
                    "dependsOn")) {
                final Vertex otherBundle = dep
                        .getVertices(Direction.OUT, "bundle").iterator().next();
                if (!todo.contains(otherBundle) && !done.contains(otherBundle)) {
                    todo.add(otherBundle);
                }
            }
        }
        return done.toArray(new Vertex[done.size()]);
    }

    /**
     * Finds the bundle depended on, with the given name, by this "feature".
     */
    public static Vertex findBundleByName(final Vertex appFeature,
            final String name) {
        for (final Vertex bundle : allBundles(appFeature)) {
            if (name.equals(bundle.getProperty("name"))) {
                return bundle;
            }
        }
        return null;
    }

    /** Generate a property name from a method. */
    public static String getPropertyNameFor(final Method annotatedElement) {
        String name = annotatedElement.getName();
        if (name.startsWith("is") && (name.length() > 2)
                && Character.isUpperCase(name.charAt(2))) {
            name = Character.toLowerCase(name.charAt(2)) + name.substring(3);
        } else if ((name.startsWith("get") || name.startsWith("set")
                || name.startsWith("has") || name.startsWith("can"))
                && (name.length() > 3) && Character.isUpperCase(name.charAt(3))) {
            name = Character.toLowerCase(name.charAt(3)) + name.substring(4);
        }
        return name;
    }

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    public static int distanceFromRoot(final Vertex appFeature,
            final Vertex otherBundle) {
        final Vertex rootBundle = Objects.requireNonNull(appFeature)
                .getVertices(Direction.OUT, "bundle").iterator().next();
        // TODO Like allBundles but use maps, where value is distance. Tricky part
        // is that there might be multiple ways with different distances
        return 0;
    }

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    public static int distanceFromRoot(final Feature appFeature,
            final Bundle otherBundle) {
        // TODO Like allBundles but use maps, where value is distance. Tricky part
        // is that there might be multiple ways with different distances
        return 0;
    }
}
