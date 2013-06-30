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
package com.blockwithme.meta.infrastructure;

import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * A node can be either a hardware node, or a virtual node.
 *
 * The children nodes are normally virtual nodes, within a hardware node.
 *
 * We assume then Networks are statically configured...
 *
 * @author monster
 */
@TypeValue("Node")
public interface Node extends ExecutionEnvironment {
    /** The network names of this node, in the given network, if any. */
    // TODO
//    String[] networkNames(final Network network);

    /** Returns true if the node has the given name, in the given network. */
    // TODO
//    boolean hasNetworkName(final Network network, final String name);

    /** The network addresses of this node, in the given network, if any. */
    // TODO
//    String[] networkAddresses(final Network network);

    /** Returns true if the node has the given address, in the given network. */
    // TODO
//    boolean hasNetworkAddress(final Network network, final String address);

    /** A node can be running any number of processes. */
    @Adjacency(label = "runs")
    Process[] getProcesses();

    /** Adds a process. */
    @Adjacency(label = "runs")
    void addProcess(final Process process);

    /** Removes a process. */
    @Adjacency(label = "runs")
    void removeProcess(final Process process);

    /** Returns the process with the given name, if any. */
    @GremlinGroovy("it.out('runs').has('name',name)")
    Process findProcess(@GremlinParam("name") final String name);

    /** A node can have any number of storages. */
    @Adjacency(label = "hosts")
    Storage[] getStorages();

    /** Adds a storage. */
    @Adjacency(label = "hosts")
    void addStorage(final Storage storage);

    /** Removes a storage. */
    @Adjacency(label = "hosts")
    void removeStorage(final Storage storage);

    /** Returns the storage with the given name, if any. */
    @GremlinGroovy("it.out('hosts').has('name',name)")
    Storage findStorage(@GremlinParam("name") final String name);
}
