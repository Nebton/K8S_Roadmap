import React, { useState, useEffect } from 'react';
import { Terminal, Server, Shield, Database, Activity, Cloud, Box, AlertTriangle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

const CyberpunkDashboard = ({ message, secret, database_url, api_url, log_level }) => {
  const [currentTime, setCurrentTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const infrastructureComponents = {
    'Developer Tools': [
      { name: 'GitHub', icon: <Box className="w-4 h-4" />, status: 'active' },
      { name: 'Docker Desktop', icon: <Box className="w-4 h-4" />, status: 'active' }
    ],
    'CI/CD': [
      { name: 'Jenkins Pipeline', icon: <Terminal className="w-4 h-4" />, status: 'active' },
      { name: 'Trivy Scanner', icon: <Shield className="w-4 h-4" />, status: 'active' },
      { name: 'Checkov', icon: <Shield className="w-4 h-4" />, status: 'active' },
      { name: 'Container Registry', icon: <Box className="w-4 h-4" />, status: 'active' }
    ],
    'Infrastructure': [
      { name: 'Terraform', icon: <Cloud className="w-4 h-4" />, status: 'active' },
      { name: 'Ansible', icon: <Terminal className="w-4 h-4" />, status: 'active' },
      { name: 'Helm', icon: <Cloud className="w-4 h-4" />, status: 'active' }
    ],
    'K8s Services': [
      { name: 'Istio Gateway', icon: <Server className="w-4 h-4" />, status: 'active' },
      { name: 'Virtual Services', icon: <Server className="w-4 h-4" />, status: 'active' },
      { name: 'Network Policies', icon: <Shield className="w-4 h-4" />, status: 'active' },
      { name: 'RBAC', icon: <Shield className="w-4 h-4" />, status: 'active' }
    ],
    'Security': [
      { name: 'Vault', icon: <Shield className="w-4 h-4" />, status: 'active' },
      { name: 'mTLS', icon: <Shield className="w-4 h-4" />, status: 'active' }
    ],
    'Observability': [
      { name: 'Prometheus', icon: <Activity className="w-4 h-4" />, status: 'active' },
      { name: 'Elasticsearch', icon: <Database className="w-4 h-4" />, status: 'active' },
      { name: 'Grafana', icon: <Activity className="w-4 h-4" />, status: 'active' },
      { name: 'Kibana', icon: <Activity className="w-4 h-4" />, status: 'active' },
      { name: 'Alert Manager', icon: <AlertTriangle className="w-4 h-4" />, status: 'active' }
    ],
    'Data Layer': [
      { name: 'Databases', icon: <Database className="w-4 h-4" />, status: 'active' },
      { name: 'Redis Cache', icon: <Database className="w-4 h-4" />, status: 'active' }
    ]
  };

  return (
    <div className="min-h-screen bg-black text-green-400 p-6 font-mono">
      {/* Header */}
      <div className="border-b border-green-500 mb-8 pb-4">
        <div className="flex items-center justify-between">
          <h1 className="text-4xl font-bold text-green-500 animate-pulse">
            DevSecOps Control Center
          </h1>
          <div className="text-xl">
            <span className="mr-2">System Time:</span>
            <span className="bg-green-900 px-3 py-1 rounded">{currentTime}</span>
          </div>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* System Status */}
        <Card className="bg-black border-green-500 border-2">
          <CardContent className="p-6">
            <div className="flex items-center mb-4">
              <Terminal className="w-6 h-6 mr-2" />
              <h2 className="text-2xl font-bold">System Status</h2>
            </div>
            <div className="space-y-2">
              <div className="flex items-center">
                <span className="w-3 h-3 rounded-full bg-green-500 mr-2 animate-pulse"></span>
                <span>Backend Connection: {message}</span>
              </div>
              <div className="flex items-center">
                <span className="w-3 h-3 rounded-full bg-green-500 mr-2 animate-pulse"></span>
                <span>Log Level: {log_level}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Security Info */}
        <Card className="bg-black border-green-500 border-2">
          <CardContent className="p-6">
            <div className="flex items-center mb-4">
              <Shield className="w-6 h-6 mr-2" />
              <h2 className="text-2xl font-bold">Security Status</h2>
            </div>
            <div className="space-y-2">
              <div className="bg-green-900/30 p-2 rounded">
                <span className="text-xs uppercase">Vault Secret</span>
                <div className="font-bold truncate">{secret}</div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Connection Details */}
        <Card className="bg-black border-green-500 border-2">
          <CardContent className="p-6">
            <div className="flex items-center mb-4">
              <Server className="w-6 h-6 mr-2" />
              <h2 className="text-2xl font-bold">Connection Details</h2>
            </div>
            <div className="space-y-2">
              <div className="flex items-center">
                <Database className="w-4 h-4 mr-2" />
                <span className="truncate">DB URL: {database_url}</span>
              </div>
              <div className="flex items-center">
                <Activity className="w-4 h-4 mr-2" />
                <span className="truncate">API URL: {api_url}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Infrastructure Map - Full Width */}
        <Card className="bg-black border-green-500 border-2 lg:col-span-3">
          <CardContent className="p-6">
            <div className="flex items-center mb-6">
              <Terminal className="w-6 h-6 mr-2" />
              <h2 className="text-2xl font-bold">Infrastructure Map</h2>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
              {Object.entries(infrastructureComponents).map(([category, items]) => (
                <div key={category} className="space-y-3">
                  <h3 className="text-lg font-bold text-green-500 border-b border-green-500 pb-2">
                    {category}
                  </h3>
                  <div className="space-y-2">
                    {items.map((item) => (
                      <div key={item.name} className="flex items-center space-x-2 bg-green-900/20 p-2 rounded">
                        <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                        {item.icon}
                        <span className="text-sm">{item.name}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Footer */}
      <div className="mt-8 text-center text-sm">
        <span className="opacity-50">SECURE CONNECTION ESTABLISHED - ALL SYSTEMS NOMINAL</span>
      </div>
    </div>
  );
};

export default CyberpunkDashboard;
