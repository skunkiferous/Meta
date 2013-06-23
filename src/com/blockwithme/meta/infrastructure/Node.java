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

import com.blockwithme.meta.Dynamic;

/**
 * A node can be either a hardware node, or a virtual node.
 *
 * The children nodes are normally virtual nodes, within a hardware node.
 *
 * We assume then Networks are statically configured...
 *
 * @author monster
 */
public interface Node<PARENT extends ExecutionEnvironment<PARENT, ?>> extends
        ExecutionEnvironment<Node<PARENT>, PARENT> {
    /** The network names of this node, in the given network, if any. */
    String[] networkNames(final Network<PARENT> network);

    /** Returns true if the node has the given name, in the given network. */
    boolean hasNetworkName(final Network<PARENT> network, final String name);

    /** The network addresses of this node, in the given network, if any. */
    String[] networkAddresses(final Network<PARENT> network);

    /** Returns true if the node has the given address, in the given network. */
    boolean hasNetworkAddress(final Network<PARENT> network,
            final String address);

    /** A node can be running any number of processes. */
    @Dynamic
    Process[] processes();

    /** A node can have any number of storages. */
    @Dynamic
    Storage[] storages();
}
