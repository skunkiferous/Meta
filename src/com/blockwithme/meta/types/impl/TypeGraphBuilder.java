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
import java.util.Objects;

import org.reflections.Reflections;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.annotations.impl.AnnotationReaderImpl;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;
import com.blockwithme.meta.types.TypeRange;
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
//                new GremlinGroovyModule(), new JavaHandlerModule(), Statics.module());
//        return factory.create(baseGraph);
//    }

    private static void copyProps(final PropMap src, final Element dst) {
        for (final String key : src.keySet()) {
            dst.setProperty(key, src.get(key));
        }
    }

    private Type buildType(final FramedGraph<TinkerGraph> graph,
            final AnnotatedType at, final Bundle bundle) {
        final Type result = graph.addVertex(null, Type.class);
        final PropMap data = at.getTypeData().get(
                com.blockwithme.meta.types.annotations.Type.class);
        copyProps(data, result);
        result.setBundle(bundle);
        return result;
    }

    private static Type getType(final Map<Class<?>, Type> types,
            final Class<?> wanted) {
        return Objects.requireNonNull(types.get(wanted), wanted + " not found");
    }

    private void buildPropertiesTypeRangesContainers(
            final FramedGraph<TinkerGraph> graph, final AnnotatedType at,
            final Type type, final Map<Class<?>, Type> types) {
        for (final Method m : at.getMethods()) {
            final Map<Class<?>, PropMap> map = at.getMethodData(m);
            final PropMap propData = map.get(Property.class);
            if (propData != null) {
                final Property prop = graph.addVertex(null, Property.class);
                copyProps(propData, prop);
                prop.setBundle(type.getBundle());
                type.addProperty(prop);
                prop.setType(type);
                final PropMap typeRangeData = propData.get("typeRange",
                        PropMap.class);
                final TypeRange typeRange = graph.addVertex(null,
                        TypeRange.class);
                copyProps(typeRangeData, typeRange);
                typeRange.setBundle(type.getBundle());
                typeRange.setDeclaredType(getType(types, m.getReturnType()));
                for (final Class<?> accepted : typeRangeData.get("accepts",
                        Class[].class)) {
                    typeRange.addAcceptedType(getType(types, accepted));
                }
                for (final Class<?> rejected : typeRangeData.get("rejects",
                        Class[].class)) {
                    typeRange.addRejectedType(getType(types, rejected));
                }
                prop.setTypeRange(typeRange);
                for (final Type t : types.values()) {
                    if (typeRange.accept(t)) {
                        t.addContainer(prop);
                    }
                }
            }
        }
    }

    public void build(final FramedGraph<TinkerGraph> graph,
            final PropMap context, final Reflections packages,
            final Bundle bundle) {
        final AnnotationReader ar = new AnnotationReaderImpl(context);
        @SuppressWarnings("unchecked")
        final Map<String, AnnotatedType> metaInfo = ar.read(packages,
                com.blockwithme.meta.types.annotations.Type.class,
                com.blockwithme.meta.types.annotations.Property.class);

        final Map<Class<?>, Type> types = new HashMap<Class<?>, Type>();
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = buildType(graph, at, bundle);
            types.put(at.getType(), type);
        }
        for (final AnnotatedType at : metaInfo.values()) {
            final Type type = types.get(at.getType());
            buildPropertiesTypeRangesContainers(graph, at, type, types);
        }
    }
}
