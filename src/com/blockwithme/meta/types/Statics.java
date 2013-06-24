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
package com.blockwithme.meta.types;

import java.util.Set;
import java.util.TreeSet;

import org.reflections.Reflections;

import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.Module;
import com.tinkerpop.frames.typed.TypeValue;
import com.tinkerpop.frames.typed.TypedGraphModuleBuilder;

/**
 * @author monster
 *
 */
public class Statics {

    private static Set<Class<?>> typedInterfaces;

    /** toString() for a TypedVertex. */
    public static String toString(final Vertex vertex) {
        final StringBuilder buf = new StringBuilder();
        buf.append(vertex.getProperty("class")).append("(id=")
                .append(vertex.getId());
        for (final String key : new TreeSet<String>(vertex.getPropertyKeys())) {
            if (!"class".equals(key)) {
                buf.append(",").append(key).append("=")
                        .append(vertex.getProperty(key));
            }
        }
        buf.append(")");
        return buf.toString();
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
        if ((incremental < 0) || (incremental >= 1024)) {
            throw new IllegalArgumentException(version);
        }
        return major * 1024 * 1024 + minor * 1024 + incremental;
    }
}
