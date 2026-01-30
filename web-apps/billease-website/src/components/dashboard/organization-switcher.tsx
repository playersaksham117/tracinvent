'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Organization } from '@/lib/organization'

interface OrganizationSwitcherProps {
  organizations: Organization[]
}

export function OrganizationSwitcher({ organizations }: OrganizationSwitcherProps) {
  const router = useRouter()
  const [current, setCurrent] = useState(organizations[0])
  const [isOpen, setIsOpen] = useState(false)

  const handleSwitch = (org: Organization) => {
    setCurrent(org)
    setIsOpen(false)
    // In a full implementation, you'd store this in cookies/local storage
    // and use it throughout the app
    router.refresh()
  }

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 rounded-md hover:bg-gray-100 transition-colors"
      >
        <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white font-medium">
          {current?.name.charAt(0).toUpperCase()}
        </div>
        <div className="text-left hidden sm:block">
          <p className="text-sm font-medium text-gray-900">{current?.name}</p>
          <p className="text-xs text-gray-500">{current?.role}</p>
        </div>
        <svg
          className={`w-4 h-4 text-gray-500 transition-transform ${
            isOpen ? 'transform rotate-180' : ''
          }`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </button>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute top-full left-0 mt-2 w-64 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-20">
            <div className="px-4 py-2 border-b border-gray-200">
              <p className="text-xs font-medium text-gray-500 uppercase">
                Your Organizations
              </p>
            </div>
            
            {organizations.map((org) => (
              <button
                key={org.id}
                onClick={() => handleSwitch(org)}
                className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors ${
                  current?.id === org.id ? 'bg-blue-50' : ''
                }`}
              >
                <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-medium">
                  {org.name.charAt(0).toUpperCase()}
                </div>
                <div className="text-left flex-1">
                  <p className="text-sm font-medium text-gray-900">{org.name}</p>
                  <p className="text-xs text-gray-500">{org.role}</p>
                </div>
                {current?.id === org.id && (
                  <svg
                    className="w-5 h-5 text-blue-600"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clipRule="evenodd"
                    />
                  </svg>
                )}
              </button>
            ))}

            <div className="border-t border-gray-200 mt-2 pt-2">
              <a
                href="/onboarding"
                className="flex items-center gap-3 px-4 py-3 text-sm text-blue-600 hover:bg-gray-50 transition-colors"
              >
                <svg
                  className="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                  />
                </svg>
                Create New Organization
              </a>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
