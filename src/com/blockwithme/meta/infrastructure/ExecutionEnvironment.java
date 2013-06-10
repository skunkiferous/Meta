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

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.Dynamic;

/**
 * An execution environment defines the context in which an application runs.
 *
 * It can be either a cluster or a node.
 *
 * We assume Networks are statically configured...
 *
 * @author monster
 */
public interface ExecutionEnvironment<EE extends ExecutionEnvironment<EE>>
        extends Definition<EE> {
    /**
     * Returns the networks (at least one) of this execution environment.
     *
     * Note that those are the network *contained* in this execution
     * environment. The network of the cluster that a node is on, should not
     * be returned by the node.
     */
    Network[] networks();

    /** Returns the network with the given name, if any. */
    Network findNetwork(final String name);

    /** Returns the *current* list of nodes. */
    @Dynamic
    Node[] nodes();

    /** Returns the node with the give network name, in the given network, if any. */
    Node findNodeByNetworkName(final Network network, final String name);

    /** Returns the node with the give network addresses, in the given network, if any. */
    Node findNodeByNetworkAddress(final Network network, final String address);
}
