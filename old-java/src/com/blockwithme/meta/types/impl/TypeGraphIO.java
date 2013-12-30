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

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;

import com.blockwithme.meta.types.Access;
import com.blockwithme.meta.types.BundleLifecycle;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.ServiceType;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.blueprints.util.io.graphml.GraphMLReader;
import com.tinkerpop.blueprints.util.io.graphml.GraphMLWriter;
import com.tinkerpop.frames.FramedGraph;

/**
 * TypeGraphIO implements reading and writing graph to files.
 *
 * TODO *Input* has NOT been tested at all!
 *
 * @author monster
 */
public class TypeGraphIO {
    /** Outputs the graph to the given file. */
    public static void output(final FramedGraph<TinkerGraph> graph,
            final String filename) throws IOException {
        final GraphMLWriter gw = new GraphMLWriter(graph.getBaseGraph());
        gw.setNormalize(true);
        gw.outputGraph(filename);
    }

    /** Outputs the graph to the given output stream. */
    public static void output(final FramedGraph<TinkerGraph> graph,
            final OutputStream out) throws IOException {
        final GraphMLWriter gw = new GraphMLWriter(graph);
        gw.setNormalize(true);
        gw.outputGraph(out);
    }

    /** Converts a property to a class. */
    private static void toClass(final Vertex v, final String prop) {
        final String value = v.getProperty(prop);
        if ((value == null) || value.isEmpty()) {
            v.removeProperty(prop);
        } else {
            try {
                if (value.startsWith("class ")) {
                    v.setProperty(prop,
                            Class.forName(value.substring("class ".length())));
                } else if (value.startsWith("interface ")) {
                    v.setProperty(prop, Class.forName(value
                            .substring("interface ".length())));
                } else if (value.startsWith("enum ")) {
                    v.setProperty(prop,
                            Class.forName(value.substring("enum ".length())));
                } else {
                    // Assume somehow no prefix ...
                    v.setProperty(prop, Class.forName(value));
                }
            } catch (final ClassNotFoundException e) {
                throw new IllegalStateException(
                        "Could not parse type " + value, e);
            }
        }
    }

    /** Converts a property to an enum. */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private static void toEnum(final Vertex v, final String prop,
            final Class<? extends Enum> type) {
        final String value = v.getProperty(prop);
        if ((value == null) || value.isEmpty()) {
            v.removeProperty(prop);
        } else {
            v.setProperty(prop, Enum.valueOf(type, value));
        }
    }

    /** Converts a property to a String list. */
    private static void toStringList(final Vertex v, final String prop) {
        final String value = v.getProperty(prop);
        if ((value == null) || value.isEmpty()) {
            v.removeProperty(prop);
        } else if ((value.charAt(0) == '[')
                && (value.charAt(value.length() - 1) == ']')) {
            final String[] array = value.substring(1, value.length() - 1)
                    .split(",");
            v.setProperty(prop, new ArrayList<>(Arrays.asList(array)));
        } else {
            throw new IllegalStateException("Could not parse String list "
                    + value);
        }
    }

    /** Convert the Feature Vertex properties, to match the expected Frames type. */
    private static void inputFeature(final Vertex v) {
        // NOP
    }

    /** Convert the Bundle Vertex properties, to match the expected Frames type. */
    private static void inputBundle(final Vertex v) {
        toEnum(v, "lifecycle", BundleLifecycle.class);
    }

    /** Convert the Property Vertex properties, to match the expected Frames type. */
    private static void inputProperty(final Vertex v) {
        // NOP
    }

    /** Convert the Type Vertex properties, to match the expected Frames type. */
    private static void inputType(final Vertex v) {
        toClass(v, "implements");
        toEnum(v, "kind", Kind.class);
        toEnum(v, "access", Access.class);
        toStringList(v, "persistence");
    }

    /** Convert the TypeRange Vertex properties, to match the expected Frames type. */
    private static void inputTypeRange(final Vertex v) {
        // NOP
    }

    /** Convert the Service Vertex properties, to match the expected Frames type. */
    private static void inputService(final Vertex v) {
        toEnum(v, "lifecycle", ServiceType.class);
    }

    /** Convert the Dependency Vertex properties, to match the expected Frames type. */
    private static void inputDependency(final Vertex v) {
        // NOP
    }

    /** Process the read graph, converting "stringed" data back to it's real type. */
    private static void processInputGraph(final Graph base) {
        for (final Vertex v : base.getVertices()) {
            final String clazz = v.getProperty("class");
            if ("Type".equals(clazz)) {
                inputType(v);
            } else if ("Bundle".equals(clazz)) {
                inputBundle(v);
            } else if ("Property".equals(clazz)) {
                inputProperty(v);
            } else if ("TypeRange".equals(clazz)) {
                inputTypeRange(v);
            } else if ("Service".equals(clazz)) {
                inputService(v);
            } else if ("Feature".equals(clazz)) {
                inputFeature(v);
            } else if ("Dependency".equals(clazz)) {
                inputDependency(v);
            } else {
                throw new IllegalStateException("Unknown Vertex type: " + clazz);
            }
        }
    }

    /** Inputs the graph from the given file. */
    public static void input(final FramedGraph<TinkerGraph> graph,
            final String filename) throws IOException {
        final Graph base = graph.getBaseGraph();
        final GraphMLReader gr = new GraphMLReader(base);
        gr.inputGraph(filename);
        processInputGraph(base);
    }

    /** Inputs the graph from the input stram. */
    public static void input(final FramedGraph<TinkerGraph> graph,
            final InputStream in) throws IOException {
        final Graph base = graph.getBaseGraph();
        final GraphMLReader gr = new GraphMLReader(base);
        gr.inputGraph(in);
        processInputGraph(base);
    }
}
