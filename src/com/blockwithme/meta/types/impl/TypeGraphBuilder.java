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

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

import org.reflections.Reflections;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.annotations.impl.AnnotationReaderImpl;
import com.blockwithme.meta.annotations.impl.PropMapImpl;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;
import com.tinkerpop.blueprints.Element;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.frames.FramedGraph;

/**
 * @author monster
 *
 */
public class TypeGraphBuilder {
//
//    private static FramedGraph<TinkerGraph> newGraph() {
//        final TinkerGraph baseGraph = new TinkerGraph();
//        final FramedGraphFactory factory = new FramedGraphFactory(
//                new GremlinGroovyModule(), Statics.module());
//        return factory.create(baseGraph);
//    }

    private static void copyProps(final PropMap src, final Element dst) {
        for (final String key : src.keySet()) {
            dst.setProperty(key, src.get(key));
        }
    }

    private Type buildType(final FramedGraph<TinkerGraph> graph,
            final AnnotatedType at) {
        final Type result = graph.addVertex(null, Type.class);
        final PropMap data = at.getTypeData().get(
                com.blockwithme.meta.types.annotations.Type.class);
        copyProps(data, result);
        return result;
    }

    private void buildPropertiesContainersTypeRanges(
            final FramedGraph<TinkerGraph> graph, final AnnotatedType at,
            final Type type, final Map<Class<?>, Type> types) {
        for (final Method m : at.getMethods()) {
            final Map<Class<?>, PropMap> map = at.getMethodData(m);
            final PropMap pm = map.get(Property.class);
            if (pm != null) {
                // TODO Create Property
                // TODO Set Property in parent type
                // TODO Create Container
                // TODO Set Container in referenced type
                // TODO Create TypeRange
                // ...
            }
        }
    }

    public void build(final FramedGraph<TinkerGraph> graph,
            final PropMap context, final Reflections packages,
            final Bundle bundle) {
        final AnnotationReader ar = new AnnotationReaderImpl(new PropMapImpl());
        @SuppressWarnings("unchecked")
        final Map<String, AnnotatedType> metaInfo = ar.read(packages,
                com.blockwithme.meta.types.annotations.Type.class,
                com.blockwithme.meta.types.annotations.Property.class);

        final Map<Class<?>, Type> types = new HashMap<Class<?>, Type>();
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = buildType(graph, at);
            types.put(at.getType(), type);
        }
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = types.get(at.getType());
            buildPropertiesContainersTypeRanges(graph, at, type, types);
        }
    }
}
