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

import junit.framework.TestCase;

import com.blockwithme.meta.infrastructure.Connector;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.frames.FramedGraph;
import com.tinkerpop.frames.FramedGraphFactory;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovyModule;

/**
 * @author monster
 *
 */
public class TypesTest extends TestCase {

    private static FramedGraph<TinkerGraph> newGraph() {
        final TinkerGraph baseGraph = new TinkerGraph();
        final FramedGraphFactory factory = new FramedGraphFactory(
                new GremlinGroovyModule(), Statics.module());
        return factory.create(baseGraph);
    }

    /**
     * Construct new test instance
     *
     * @param name the test name
     */
    public TypesTest(final String name) {
        super(name);
    }

    public void testNamed() {
        final FramedGraph<TinkerGraph> framedGraph = newGraph();
        final Named named = framedGraph.addVertex("1", Named.class);
        named.setName("John");
        assertEquals("John", named.getName());
        assertEquals("Named(id=1,name=John)", named.getString());
    }

    public void testFindNamed() {
        final FramedGraph<TinkerGraph> framedGraph = newGraph();

        final Application app = framedGraph.addVertex("1", Application.class);
        app.setName("app");

        final Connector http = framedGraph.addVertex("2", Connector.class);
        http.setName("http");

        final Connector ftp = framedGraph.addVertex("3", Connector.class);
        ftp.setName("ftp");

        app.addConnector(http);
        app.addConnector(ftp);

        assertEquals(ftp, app.findConnector("ftp"));
    }

}
